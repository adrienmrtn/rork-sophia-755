package app.rork.sophia.data

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

data class DiscountState(
    val startEpochMs: Long? = null,
    val isExpiredForever: Boolean = false,
    val swipeCount: Int = 0,
    val isGiftPending: Boolean = false,
    val lastShownDay: String? = null,
    val swipeDay: String? = null,
    val remainingSeconds: Long = 0,
    /**
     * The running or last offer was started by a cancelled checkout (test
     * `checkout_cancel_ab`), not by the gift earned by swiping. Such an offer never takes the
     * place of the day's gift: the swipes still earn it, as if nothing had been shown.
     */
    val startedByCancel: Boolean = false,
    /** The day a cancelled checkout last started an offer: once a day at most. */
    val cancelDay: String? = null,
) {
    val isActive: Boolean
        get() {
            if (isExpiredForever || startEpochMs == null) return false
            val elapsed = System.currentTimeMillis() - startEpochMs
            return elapsed in 0 until DURATION_MS
        }

    val hasBeenTriggered: Boolean
        get() = startEpochMs != null || isExpiredForever

    val formattedRemaining: String
        get() {
            val m = remainingSeconds / 60
            val s = remainingSeconds % 60
            return "%02d:%02d".format(m, s)
        }

    companion object {
        const val DURATION_MS = 60L * 60L * 1000L
        const val SWIPES_BEFORE_GIFT = 3
    }
}

class DiscountOfferManager(context: Context) {
    private val prefs = context.getSharedPreferences("sophia_prefs", Context.MODE_PRIVATE)
    private val scope = CoroutineScope(Dispatchers.Main.immediate)
    private var ticker: Job? = null

    private val _state = MutableStateFlow(load())
    val state: StateFlow<DiscountState> = _state.asStateFlow()

    init {
        maybeExpireFromElapsed()
        if (_state.value.isActive) startTicker()
    }

    private fun today(): String = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)

    private fun load(): DiscountState {
        val start = prefs.getLong(KEY_START, -1L).takeIf { it > 0 }
        var expired = prefs.getBoolean(KEY_EXPIRED, false)
        if (start != null && System.currentTimeMillis() - start >= DiscountState.DURATION_MS) {
            expired = true
        }
        val remaining = if (start != null && !expired) {
            ((DiscountState.DURATION_MS - (System.currentTimeMillis() - start)) / 1000).coerceAtLeast(0)
        } else 0
        return DiscountState(
            startEpochMs = start,
            isExpiredForever = expired,
            swipeCount = prefs.getInt(KEY_SWIPES, 0),
            isGiftPending = prefs.getBoolean(KEY_GIFT, false),
            lastShownDay = prefs.getString(KEY_SHOWN_DAY, null),
            swipeDay = prefs.getString(KEY_SWIPE_DAY, null),
            remainingSeconds = remaining,
            startedByCancel = prefs.getBoolean(KEY_BY_CANCEL, false),
            cancelDay = prefs.getString(KEY_CANCEL_DAY, null),
        )
    }

    /**
     * Single entry point for discount writes. [transform] must not touch [_state]:
     * this is a plain read-modify-write, not a compare-and-set retry.
     */
    private fun mutate(transform: (DiscountState) -> DiscountState) {
        val current = _state.value
        val next = transform(current)
        if (next == current) return
        persist(next)
    }

    private fun persist(s: DiscountState) {
        prefs.edit()
            .putLong(KEY_START, s.startEpochMs ?: -1L)
            .putBoolean(KEY_EXPIRED, s.isExpiredForever)
            .putInt(KEY_SWIPES, s.swipeCount)
            .putBoolean(KEY_GIFT, s.isGiftPending)
            .putString(KEY_SHOWN_DAY, s.lastShownDay)
            .putString(KEY_SWIPE_DAY, s.swipeDay)
            .putBoolean(KEY_BY_CANCEL, s.startedByCancel)
            .putString(KEY_CANCEL_DAY, s.cancelDay)
            .apply()
        _state.value = s
    }

    private fun maybeExpireFromElapsed() {
        val s = _state.value
        val start = s.startEpochMs ?: return
        if (!s.isExpiredForever && System.currentTimeMillis() - start >= DiscountState.DURATION_MS) {
            persist(s.copy(isExpiredForever = true, remainingSeconds = 0))
        }
    }

    fun wasShownToday(): Boolean = _state.value.lastShownDay == today()

    fun registerSwipe() {
        if (wasShownToday()) return
        val current = _state.value
        // Parity with iOS: never re-arm the gift once the offer ran, is running, or is
        // already waiting to be opened.
        if (current.isGiftPending) return
        // An offer started by a cancelled checkout is not the day's gift: the swipes go on counting.
        if (!current.startedByCancel) {
            if (current.startEpochMs != null && current.swipeDay == today()) return
            if (current.isExpiredForever && current.swipeDay == today()) return
        }
        val today = today()
        mutate { current ->
            val base = if (current.swipeDay != today) {
                if (current.startedByCancel && current.isActive) {
                    // The countdown a cancelled checkout started today keeps running.
                    current.copy(swipeDay = today, swipeCount = 0, isGiftPending = false)
                } else {
                    current.copy(
                        swipeDay = today,
                        swipeCount = 0,
                        isGiftPending = false,
                        startEpochMs = null,
                        isExpiredForever = false,
                        remainingSeconds = 0,
                        startedByCancel = false,
                    )
                }
            } else {
                current
            }
            val count = base.swipeCount + 1
            base.copy(
                swipeCount = count,
                isGiftPending = base.isGiftPending || count >= DiscountState.SWIPES_BEFORE_GIFT,
            )
        }
    }

    fun consumeGift() {
        mutate { it.copy(isGiftPending = false) }
    }

    fun triggerIfNeeded() {
        maybeExpireFromElapsed()
        val s = _state.value
        if (s.startedByCancel) {
            // The gift opens over an offer a cancelled checkout started: it becomes the day's
            // offer. Still running, its countdown goes on; over, the gift starts a fresh one.
            if (s.isActive) {
                mutate { it.copy(startedByCancel = false) }
                return
            }
        } else if (s.hasBeenTriggered) {
            return
        }
        mutate { current ->
            current.copy(
                startEpochMs = System.currentTimeMillis(),
                isExpiredForever = false,
                remainingSeconds = DiscountState.DURATION_MS / 1000,
                startedByCancel = false,
            )
        }
        startTicker()
    }

    /**
     * Whether the flash offer may open right after a cancelled checkout (test
     * `checkout_cancel_ab`): it is running, or no cancelled checkout has started one today and
     * the day's gift offer is not already over. Reads only.
     */
    fun canOpenAfterCheckoutCancel(): Boolean {
        maybeExpireFromElapsed()
        val s = _state.value
        if (s.isActive) return true
        if (s.cancelDay == today()) return false
        return !(s.hasBeenTriggered && wasShownToday())
    }

    /**
     * Starts the offer for a cancelled checkout, or keeps the countdown already running.
     * Returns false, changing nothing, when it may not open (see [canOpenAfterCheckoutCancel]).
     * It does not use up the day's gift: the offer earned by swiping still comes as usual, with
     * this countdown if it is still running, with a fresh one otherwise.
     */
    fun openAfterCheckoutCancel(): Boolean {
        if (!canOpenAfterCheckoutCancel()) return false
        if (_state.value.isActive) return true
        val today = today()
        mutate { current ->
            current.copy(
                startEpochMs = System.currentTimeMillis(),
                isExpiredForever = false,
                remainingSeconds = DiscountState.DURATION_MS / 1000,
                startedByCancel = true,
                cancelDay = today,
            )
        }
        startTicker()
        return true
    }

    /** Wipes the promo countdown so a deleted account leaves no offer behind. */
    fun clearLocalState() {
        persist(DiscountState())
    }

    fun markExpired() {
        ticker?.cancel()
        mutate { it.copy(isExpiredForever = true, remainingSeconds = 0) }
    }

    fun markShownToday() {
        // Looking at an offer a cancelled checkout started does not use up the day's gift.
        if (_state.value.startedByCancel) return
        mutate { it.copy(lastShownDay = today()) }
    }

    private fun startTicker() {
        ticker?.cancel()
        ticker = scope.launch {
            while (isActive) {
                delay(1000)
                val s = _state.value
                val start = s.startEpochMs
                if (start == null || s.isExpiredForever) break
                val remaining = ((DiscountState.DURATION_MS - (System.currentTimeMillis() - start)) / 1000)
                if (remaining <= 0) {
                    persist(s.copy(isExpiredForever = true, remainingSeconds = 0))
                    break
                } else {
                    _state.value = s.copy(remainingSeconds = remaining)
                }
            }
        }
    }

    companion object {
        private const val KEY_START = "sophia_discount_offer_start"
        private const val KEY_EXPIRED = "sophia_discount_offer_expired"
        private const val KEY_SWIPES = "sophia_discount_swipe_count"
        private const val KEY_GIFT = "sophia_discount_gift_pending"
        private const val KEY_SHOWN_DAY = "sophia_discount_last_shown_day"
        private const val KEY_BY_CANCEL = "sophia_discount_started_by_cancel"
        private const val KEY_CANCEL_DAY = "sophia_discount_cancel_day"
        private const val KEY_SWIPE_DAY = "sophia_discount_swipe_day"
    }
}
