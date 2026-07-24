package app.rork.sophia.data

import android.content.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
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
        )
    }

    private fun persist(s: DiscountState) {
        prefs.edit()
            .putLong(KEY_START, s.startEpochMs ?: -1L)
            .putBoolean(KEY_EXPIRED, s.isExpiredForever)
            .putInt(KEY_SWIPES, s.swipeCount)
            .putBoolean(KEY_GIFT, s.isGiftPending)
            .putString(KEY_SHOWN_DAY, s.lastShownDay)
            .putString(KEY_SWIPE_DAY, s.swipeDay)
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
        val today = today()
        _state.update { current ->
            var next = current
            if (current.swipeDay != today) {
                next = current.copy(
                    swipeDay = today,
                    swipeCount = 0,
                    isGiftPending = false,
                    startEpochMs = null,
                    isExpiredForever = false,
                    remainingSeconds = 0,
                )
            }
            val count = next.swipeCount + 1
            next = next.copy(swipeCount = count)
            if (count >= DiscountState.SWIPES_BEFORE_GIFT) {
                next = next.copy(isGiftPending = true)
            }
            persist(next)
            next
        }
    }

    fun consumeGift() {
        _state.update { persist(it.copy(isGiftPending = false)); it.copy(isGiftPending = false) }
    }

    fun triggerIfNeeded() {
        _state.update { current ->
            if (current.hasBeenTriggered) current
            else {
                val next = current.copy(
                    startEpochMs = System.currentTimeMillis(),
                    isExpiredForever = false,
                    remainingSeconds = DiscountState.DURATION_MS / 1000,
                )
                persist(next)
                startTicker()
                next
            }
        }
    }

    fun markExpired() {
        _state.update {
            val next = it.copy(isExpiredForever = true, remainingSeconds = 0)
            persist(next)
            ticker?.cancel()
            next
        }
    }

    fun markShownToday() {
        _state.update {
            val next = it.copy(lastShownDay = today())
            persist(next)
            next
        }
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
        private const val KEY_SWIPE_DAY = "sophia_discount_swipe_day"
    }
}
