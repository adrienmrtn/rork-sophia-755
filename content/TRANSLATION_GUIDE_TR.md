# Ders çevirisi — Fransızcadan Türkçeye

Fransızca (`content/courses/fr/`) kaynaktır. Bu belge `content/courses/tr/`
için yazılı şartnamedir. Çeviriyi yazana olduğu gibi gider;
`scripts/check_course_translation.py --lang tr` kuralları mekanik uygular.

Aynı kurallar diğer diller için de geçerlidir; değişen yalnızca sayılar,
tırnaklar ve özel isimlerdir.

## 1. Ne istiyoruz

Bir çeviri teslim etmiyoruz. Dersin **Türkçe baskısını** teslim ediyoruz:
aynı notlardan anadili Türkçe bir editörün yazacağı metin. Okur, aslının
Fransızca olduğunu fark etmemeli.

Sırayla:

1. **Doğru.** Olguları çarpıtma, uydurma, atlama.
2. **Akıcı.** İdiomatik Türkçe. Sesli okununca takılmaz.
3. **Sade.** Kısa cümle. Sık kullanılan sözcükler. Meraklı bir ergen
   takip edebilmeli. “gösterdi” “tebarüz ettirdi”den iyidir, “kullandı”
   “istifade etti”den iyidir.
4. **Biçime sadık.** Neredeyse aynı cümle sayısı, aynı fikir sırası, yüzde
   yirmi payla aynı uzunluk: düzen bozulmasın.

Kayıt: **standart İstanbul Türkçesi**. Ağız yok, bürokrasi dili yok,
iç içe geçmiş uzun cümle yok. Hitap **sen**, resmi *siz* değil.
Çağdaş yazım: ğ, ı, İ, ş, ç, ö, ü yerinde; kesme işareti düz `'`
(asla `’`).

Cümleleri istediğin gibi yeniden kur. Fransızca noktalı virgülle uzun
dönemler bağlar ve tarihi şimdiki zamanda anlatır; Türkçe ders metni
tarih için genellikle **-di'li geçmiş** veya **-miş'li geçmiş** tercih
eder. Fransızca şimdiki zamanı kısa, bilinçli bir etki için kullanıyorsa
onu koru.

## 2. İskelet yerinde kalır

Yalnızca metin alanları çevrilir. Gerisini araç Fransız iskeletinden
kopyalar, dokunulmaz: `id`, `subject`, `subcategory`, `type`, `asset`,
`image`, `ratio`, `free`.

| Alan | Nedir | Not |
| --- | --- | --- |
| `title` | Kart ve hero başlığı | Kısa. Ders bir eserse Türkiye'de yayımlanmış kanonik başlık. |
| `subtitle` | Başlığın altı | Yıl veya aralık (`1945`, `1945-1975`) olduğu gibi kalır. |
| `description` | İki cümlelik tanıtım | Kendi başına ayakta durmalı. |
| `hero.hook` | Bir cümle yem | Reklam, nesir değil. |
| `sections[].title` | Bölüm başlığı | Ad tamlaması, sonda nokta yok. |
| `paragraph.text` | Akıcı metin | Asıl iş. |
| `image.caption` | Altyazı | Bir öbek; nokta yalnızca tam cümleyse. |
| `funFact.text` | Kutu | Hafif, konuşur gibi. |
| `takeaway.text` | Kapanış | Akılda kalması gereken. |
| `quote.text` | Alıntı | Bkz. §6. |
| `quote.attribution` | Kim söyledi | Bkz. §6. |
| `timeline.events[].date` | `1789`, `Haziran 1940`, `yaklaşık M.Ö. 450` | Rakamlar durur. Aylar çevrilir. `M.Ö.` / `M.S.`, asla `av. J.-C.`. |
| `timeline.events[].title` | Etiket | Çok kısa, noktasıız. |
| `timeline.events[].detail` | Bir cümle | |

## 3. Satır içi işaretler

Üç işaret hayatta kalmalıdır:

- `**kalın**` — tarih, sayı, paragrafın sözünü ettiği kişi ve eser adları.
- `*italik*` — nesir içinde eser başlığı.
- `[[terim]]` — sözlük girdisi. Dokununca tanım açılır.

Kurallar:

- İşaretler çift gider. Tek sayıda `**` hatadır.
- Hiçbir işaret boşluk veya noktalama yutmaz: `**1945**,` doğru,
  `**1945,**` ve `** 1945 **` yanlıştır.
- Kalın, Fransız karakterlerin değil Türkçe karşılığın üzerindedir.
  Fransızca `**30 000 mots**` → `**30.000 kelime**`.
- Fransızcada olmayan kalın yok. Tüm cümleyi kalın yapma.

## 4. Sözlük terimleri — en önemli kural

Her Fransız `[[...]]` tam olarak bir Türkçe `[[...]]` olur, **cümlede,
konunun aynı yerinde**.

Terimi paragrafın sonuna park etme. Deliği açık bırakma. İkisi de aynı
hatadır:

> Yanlış: `özellikle şundan zayıfladı : Hıristiyan haçlılar kenti
> yağmaladı. [[Konstantinopolis'in yağmalanması]]`
>
> Doğru: `özellikle [[Dördüncü Haçlı Seferi sırasında Konstantinopolis'in
> yağmalanması (1204)]] yüzünden zayıfladı; Batılı Hıristiyan haçlılar
> kenti yağmaladı.`

Terim metni serbest değildir. O ders için
`ios/Sophia/Resources/Locales/glossary.tr.json` içinde kayıtlı bir anahtar
olmalıdır. Bilinmeyen anahtar ölü metin olarak görünür.
`scripts/make_translation_briefs.py` brief'i izinli anahtarları listeler;
birini harf harf, büyük harfler dahil kullan.

Cümle, **terim yerleştirilmiş halde** dilbilgisine uymalıdır:

- Türkçede tanımlık yoktur. Anahtarın önüne `bir` veya `bu` ekleme, anahtar
  zaten `Bir ` veya `Bu ` ile başlıyorsa hele hiç.
- Anahtar yalın durumdadır. `]]` arkasına ek takma: `[[proletarya]]yı`
  yanlıştır. Cümleyi yeniden kur (`sömürülen [[proletarya]]`).
- Özel ada ek gerekirse cümleyi kaydır: `[[İkinci Dünya Savaşı]] sürerken`,
  asla `[[İkinci Dünya Savaşı]]'nda` gibi bir ekle yamama (ek `]]` dışında
  kalsa bile anahtar yutulur). Daha iyisi: `**[[İkinci Dünya Savaşı]]**
  sırasında`.
- Anahtar oturmuyorsa cümleyi yeniden yaz. Anahtarı değiştirme.

## 5. Özel adlar

Makine çevirisi adları cins isim sanır. Sert kurallar:

**Kişi adını asla çevirme.** Degas Degas kalır, “Gazı gidermek” olmaz.
Corneille Corneille kalır. Le Corbusier Le Corbusier kalır.

**Yerleşik Türkçe biçim**, varsa:
`Christophe Colomb` → `Kristof Kolomb`, `Guillaume le Conquérant` →
`Fatih William`, `Londres` → `Londra`, `Pékin` → `Pekin`,
`Aix-la-Chapelle` → `Aachen`, `Charlemagne` → `Şarlman`,
`Napoléon` → `Napolyon`, `Tchernobyl` → `Çernobil`.

**Eser başlıkları Türkiye'de yayımlanmış başlığı taşır**, harfiyen
kopya değil:

| Fransızca | Türkçe |
| --- | --- |
| *Impression, soleil levant* | *İzlenim, Gün Doğumu* |
| *La Ferme des animaux* | *Hayvan Çiftliği* |
| *Le Rouge et le Noir* | *Kırmızı ve Siyah* |
| *À la recherche du temps perdu* | *Kayıp Zamanın İzinde* |
| *Le Déjeuner sur l'herbe* | *Çimenler Üzerinde Öğle Yemeği* |
| *Les Demoiselles d'Avignon* | *Avignonlu Kızlar* |
| *Les Fleurs du Mal* | *Kötülük Çiçekleri* |
| *Les Misérables* | *Sefiller* |
| *Le Petit Prince* | *Küçük Prens* |
| *L'Étranger* | *Yabancı* |
| *Le Mythe de Sisyphe* | *Sisifos Söyleni* |
| *Le Père Goriot* | *Goriot Baba* |

Türkiye'de sabit bir başlık yoksa özgün adı tut, ilk geçişte parantezle
aç.

**Çevrilmiş edebiyattaki kişiler, standart Türkçe baskının adını taşır:**

| Eser | Fransızca | Türkçe |
| --- | --- | --- |
| *Hayvan Çiftliği* | Malabar | Boksör |
| *Hayvan Çiftliği* | Brille-Babil | Çığırtkan |
| *Hayvan Çiftliği* | Boule de neige | Kartopu |
| *Hayvan Çiftliği* | Vieux Major | Koca Reis |
| *Küçük Prens* | Bésixdouze | B-612 asteroidi |
| *1984* | novlangue | Yenisöylem |
| *1984* | doublepensée | çiftdüşünce |

Kayıt `scripts/proper_nouns.json` içindedir. Oraya ekle, aynı adı iki
kez onarma.

## 6. Alıntılar

Alıntı bir çeviri alıştırması değildir. Yayımlanmış kanonik bir Türkçe
söyleyiş varsa onu kullan. Yoksa kısa ve açık çevir.

- Eğri tırnak `“ ”`. Fransız köşeli tırnak `« »` yok.
- Alıntı cümlesinin noktası kapanış tırnağının içinde:
  `“Bütün hayvanlar eşittir.”`
- `quote.attribution` biçimi `Yazar, Eser`. Fransızca konuşanı tire,
  virgül veya parantezle veriyorsa:
  `Victor Hugo, Sefiller (Monseigneur Bienvenu)`.

## 7. Noktalama ve tipografi

Mekanik denetim, istisna yok.

- **Uzun tire `—` yok, orta tire `–` yok.** Virgül, iki nokta, parantez
  veya nokta ile yeniden yaz. Sayı aralıkları kısa tire: `1945-1975`.
- `« »` yok, sıfır genişlikli karakter yok, bölünemez boşluk yok.
- Kesme işareti düz `'` (U+0027), Fransız dosyalardaki gibi. `’` yok.
  Sayı ve özel ada ek: `1945'te`, `Orwell'in`.
- `, . ; : ! ?` önünde boşluk yok. Çift boşluk yok.
- İki nokta veya noktalı virgülden sonra bir boşluk; ikisini de az kullan:
  Türkçe ders nesri noktayı tercih eder.
- Fransızca artık yok. Bir Türkçe paragrafta `siècle`, `dans`, `l'`,
  `d'un` hata sayılır; çevrilmemiş bir Fransız yer adı da öyle.

## 8. Sayılar, tarihler, birimler

- Binlik: nokta. `30 000` → `30.000`. Ne boşluk, ne virgül.
- Ondalık: virgül. `3,5 %` → `3,5%`. `%` önünde boşluk yok.
- Yüzyıllar Arap rakamı ve nokta: `XVe siècle` → `15. yüzyıl`.
  `XVe` tek başına yok, `XV. yüzyıl` yok.
- Çağlar: `M.Ö.` ve `M.S.`: `M.Ö. 450`, `M.S. 622`.
- Tarihler: `24 Şubat 2022`. Ders başına bir şema.
- Dönüştürme yok. Metrik metrik kalır.
- `Mds`/`Md` → `milyar`. `M` → `milyon`, açık yazılır.

## 9. Denetim

```bash
python scripts/check_course_translation.py --lang tr
python scripts/check_course_translation.py --lang tr course_102_*
```

Doğrulayıcı ders başına şunları işaretler: iskelet sapması, eşleşmeyen
işaret, sözlük sayısı, kayıtsız anahtar, paragraf sonuna park edilmiş
terim, çift tanımlık, yasak karakter, boşluk, Fransız artığı ve yerelleşmemiş
sayı. Temiz geçiş bir zorunluluktur, öneri değil.
