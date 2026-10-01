/// Partner-preference option lists, ported verbatim from DuoFrontend
/// `lib/register/constants.ts` and `lib/profile/religionBackground.ts` so the
/// values saved in `pref_values` are identical on web and Android.
library;

typedef PrefOption = (String value, String label);

const prefEducationLevelOptions = <PrefOption>[
  ('below_see', 'Below SEE'),
  ('see', 'SEE / SLC'),
  ('plus_two', '+2 / Intermediate'),
  ('diploma', 'Diploma'),
  ('bachelor', "Bachelor's"),
  ('master', "Master's"),
  ('mphil', 'MPhil'),
  ('phd', 'PhD'),
  ('other', 'Other'),
];

const prefFieldOfStudyOptions = <PrefOption>[
  ('it', 'IT / Computer Science'),
  ('engineering', 'Engineering'),
  ('medical', 'Medical / Health Sciences'),
  ('business', 'Business / Management'),
  ('law', 'Law'),
  ('science', 'Science'),
  ('arts', 'Arts / Humanities'),
  ('education', 'Education'),
  ('agriculture', 'Agriculture'),
  ('hospitality', 'Hotel Management / Hospitality'),
  ('social_work', 'Social Work'),
  ('journalism', 'Journalism / Mass Communication'),
  ('fine_arts', 'Fine Arts / Design'),
  ('other', 'Other'),
];

const prefWorkOptions = <PrefOption>[
  ('Private', 'Private sector'),
  ('Government', 'Government'),
  ('Business', 'Business / self-employed'),
  ('Freelancer', 'Freelancer'),
  ('Student', 'Student'),
  ('Retired', 'Retired'),
  ('NotWorking', 'Not working'),
];

const prefIncomeOptions = <PrefOption>[
  ('below_20k', 'Below NPR 20,000'),
  ('20k_50k', 'NPR 20,000 - 50,000'),
  ('50k_100k', 'NPR 50,000 - 100,000'),
  ('100k_200k', 'NPR 100,000 - 200,000'),
  ('200k_plus', 'NPR 200,000+'),
];

const prefReligionOptions = <PrefOption>[
  ('hindu', 'Hindu'),
  ('buddhist', 'Buddhist'),
  ('muslim', 'Muslim'),
  ('christian', 'Christian'),
  ('kirat', 'Kirat'),
  ('sikh', 'Sikh'),
  ('jain', 'Jain'),
  ('jewish', 'Jewish'),
  ('non_religious', 'Non-religious'),
  ('other', 'Other'),
];

/// Rashi without "Don't know" (web filters it out for preferences).
const prefRashiOptions = <PrefOption>[
  ('mesh', 'Aries (Mesh)'),
  ('vrishabha', 'Taurus (Vrishabha)'),
  ('mithuna', 'Gemini (Mithuna)'),
  ('karka', 'Cancer (Karka)'),
  ('simha', 'Leo (Simha)'),
  ('kanya', 'Virgo (Kanya)'),
  ('tula', 'Libra (Tula)'),
  ('vrishchika', 'Scorpio (Vrishchika)'),
  ('dhanu', 'Sagittarius (Dhanu)'),
  ('makara', 'Capricorn (Makara)'),
  ('kumbha', 'Aquarius (Kumbha)'),
  ('meena', 'Pisces (Meena)'),
];

const prefPersonalityOptions = <PrefOption>[
  ('introvert', 'Introvert'),
  ('ambivert', 'Ambivert'),
  ('extrovert', 'Extrovert'),
];

const prefLifestyleOptions = <PrefOption>[
  ('active', 'Active'),
  ('balanced', 'Balanced'),
  ('relaxed', 'Relaxed'),
];

const prefFrequencyOptions = <PrefOption>[
  ('no', 'No'),
  ('occasionally', 'Occasionally'),
  ('yes', 'Yes'),
];

const prefExerciseOptions = <PrefOption>[
  ('gym', 'Gym'),
  ('yoga', 'Yoga'),
  ('sports', 'Sports'),
  ('running', 'Running'),
  ('none', 'None'),
];

/// Occupation groups; matched by keyword on the backend.
const prefOccupationOptions = <PrefOption>[
  ('software', 'Software / IT'),
  ('engineer', 'Engineer'),
  ('doctor', 'Doctor'),
  ('health', 'Nurse / Healthcare'),
  ('teacher', 'Teacher / Professor'),
  ('business', 'Business Owner / Entrepreneur'),
  ('banking', 'Banking / Finance'),
  ('accountant', 'Accountant / CA'),
  ('government', 'Government Officer'),
  ('security', 'Army / Police'),
  ('lawyer', 'Lawyer / Legal'),
  ('creative', 'Designer / Creative'),
  ('architect', 'Architect'),
  ('marketing', 'Marketing / Sales'),
  ('manager', 'Manager / Executive'),
  ('consultant', 'Consultant'),
  ('aviation', 'Pilot / Aviation'),
  ('hospitality', 'Hospitality / Tourism'),
  ('media', 'Media / Journalist'),
  ('ngo', 'NGO / INGO'),
  ('research', 'Researcher / Scientist'),
  ('abroad', 'Working Abroad'),
  ('student', 'Student'),
];

typedef PrefGroup = (String title, List<String> items);

const prefInterestGroups = <PrefGroup>[
  ('Outdoors & Adventure', [
    'Trekking', 'Hiking', 'Travel', 'Nature', 'Camping', 'Mountaineering', 'Rafting',
    'Paragliding', 'Cycling', 'Road Trips', 'Bike Rides', 'Bird Watching', 'Gardening', 'Beaches',
  ]),
  ('Sports & Fitness', [
    'Fitness', 'Gym', 'Running', 'Yoga', 'Cricket', 'Football', 'Futsal', 'Basketball',
    'Volleyball', 'Badminton', 'Table Tennis', 'Swimming', 'Martial Arts', 'Boxing', 'Chess',
  ]),
  ('Music & Arts', [
    'Music', 'Singing', 'Guitar', 'Dancing', 'Concerts', 'Art', 'Painting', 'Sketching',
    'Photography', 'Writing', 'Poetry', 'Theatre', 'Crafts', 'Fashion', 'Design',
  ]),
  ('Entertainment', [
    'Movies', 'Web Series', 'K-Drama', 'Anime', 'Gaming', 'Board Games', 'Stand-up Comedy',
    'Podcasts', 'Karaoke', 'Bollywood', 'Nepali Films',
  ]),
  ('Food & Drink', [
    'Cooking', 'Baking', 'Foodie', 'Street Food', 'Momo Lover', 'Coffee', 'Tea', 'Cafe Hopping',
    'Vegetarian', 'Trying New Restaurants',
  ]),
  ('Learning & Career', [
    'Reading', 'Coding', 'Technology', 'Business', 'Entrepreneurship', 'Startups', 'Investing',
    'Science', 'History', 'Languages', 'Public Speaking', 'Self Improvement',
  ]),
  ('Culture & Values', [
    'Spirituality', 'Meditation', 'Volunteering', 'Social Work', 'Environment', 'Festivals',
    'Heritage & Temples', 'Astrology', 'Family Time', 'Pets', 'Dogs', 'Cats',
  ]),
];

const prefLanguageGroups = <PrefGroup>[
  ('Languages of Nepal', [
    'Nepali', 'Maithili', 'Bhojpuri', 'Tharu', 'Tamang', 'Nepal Bhasa (Newari)', 'Bajjika',
    'Magar', 'Doteli', 'Urdu', 'Awadhi', 'Limbu', 'Gurung', 'Baitadeli', 'Rai (Bantawa)',
    'Achhami', 'Sherpa', 'Rajbanshi', 'Sunuwar', 'Thakali', 'Tibetan',
  ]),
  ('Widely spoken', ['English', 'Hindi', 'Bengali', 'Arabic', 'Chinese (Mandarin)', 'Spanish', 'Portuguese', 'Russian']),
  ('Popular to learn', ['Korean', 'Japanese', 'German', 'French', 'Italian', 'Turkish', 'Hebrew', 'Malay', 'Dutch']),
];

// --- Caste lists by religion (religionBackground.ts) -------------------------

const _hillHighCastes = ['Bahun', 'Chhetri', 'Thakuri', 'Sanyasi / Dashnami'];
const _madhesiCastes = [
  'Yadav', 'Kurmi', 'Teli', 'Sah / Sahu', 'Mandal', 'Kayastha', 'Rajput',
  'Brahmin (Madhesi)', 'Kalwar', 'Kanu', 'Koiri', 'Dhanuk', 'Rajbanshi', 'Tharu',
];
const _dalitCastes = [
  'Kami', 'Damai', 'Sarki', 'Sunar', 'Gaine', 'Badi', 'Chamar', 'Musahar',
  'Paswan / Dusadh', 'Dom', 'Khatik',
];
const _hinduJanajati = [
  'Magar', 'Gurung', 'Tamang', 'Sunuwar', 'Thakali', 'Gharti / Bhujel',
  'Chepang', 'Kumal', 'Majhi', 'Danuwar',
];
const _buddhistJanajati = [
  'Tamang', 'Gurung', 'Magar', 'Sherpa', 'Thakali', 'Hyolmo', 'Chepang',
  'Sunuwar', 'Gharti / Bhujel', 'Tharu',
];

final List<String> _allCastes = <String>{
  ..._hillHighCastes,
  'Newar',
  ..._hinduJanajati,
  ..._buddhistJanajati,
  'Rai',
  'Limbu',
  'Yakkha',
  ..._madhesiCastes,
  'Marwadi',
  'Baniya',
  ..._dalitCastes,
}.toList();

final Map<String, List<String>> _castesByReligion = {
  'hindu': [..._hillHighCastes, 'Newar', ..._hinduJanajati, ..._madhesiCastes, 'Marwadi', 'Baniya', ..._dalitCastes, 'Other'],
  'buddhist': ['Newar', ..._buddhistJanajati, 'Other'],
  'kirat': ['Rai', 'Limbu', 'Yakkha', 'Sunuwar', 'Other'],
  'jain': ['Marwadi', 'Baniya', 'Newar', 'Other'],
  'muslim': ['Muslim'],
  'christian': [..._allCastes, 'Other'],
  'non_religious': [..._allCastes, 'Other'],
  'other': [..._allCastes, 'Other'],
  'sikh': [],
  'jewish': [],
};

const _religionAliases = {
  'hindu': 'hindu',
  'buddhist': 'buddhist',
  'muslim': 'muslim',
  'islam': 'muslim',
  'christian': 'christian',
  'kirat': 'kirat',
  'sikh': 'sikh',
  'jain': 'jain',
  'jewish': 'jewish',
  'non-religious': 'non_religious',
  'non_religious': 'non_religious',
  'other': 'other',
};

/// Accepts either the option value ("hindu") or its label ("Hindu").
String toReligionKey(String? religion) {
  final raw = (religion ?? '').trim().toLowerCase();
  if (raw.isEmpty) return '';
  return _religionAliases[raw] ?? 'other';
}

/// Caste/community choices for a religion. Empty means the question is skipped.
List<String> casteOptionsFor(String? religion) {
  final key = toReligionKey(religion);
  return key.isEmpty ? const [] : _castesByReligion[key]!;
}

String casteLabelFor(String? religion) {
  final key = toReligionKey(religion);
  if (key == 'muslim' || key == 'kirat' || key == 'buddhist') return 'Community';
  return 'Caste / Community';
}

// --- Height (HeightSlider.tsx) ----------------------------------------------

/// Height range in whole inches: 4'6" to 7'0".
const prefHeightMinIn = 54;
const prefHeightMaxIn = 84;
const _cmPerIn = 2.54;

/// Reads "168 cm", "5'6\"", "5 ft 6 in" or "5'6\" (168 cm)" into inches.
int? parseHeightInches(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  final cm = RegExp(r'(\d{2,3})\s*cm', caseSensitive: false).firstMatch(text);
  if (cm != null) return (int.parse(cm.group(1)!) / _cmPerIn).round();
  final ftIn = RegExp(r"(\d)\s*(?:'|ft|feet)\s*(\d{1,2})?", caseSensitive: false).firstMatch(text);
  if (ftIn != null) return int.parse(ftIn.group(1)!) * 12 + int.parse(ftIn.group(2) ?? '0');
  return null;
}

String formatHeight(int inches) => "${inches ~/ 12}'${inches % 12}\" (${(inches * _cmPerIn).round()} cm)";

String shortHeight(int inches) => "${inches ~/ 12}'${inches % 12}\"";

// --- Own profile: Personal / Background options (ProfileEditForm.tsx) --------

const profileGenderSelectOptions = <PrefOption>[('M', 'Male'), ('F', 'Female'), ('O', 'Other')];

const profileRelationshipGoalSelectOptions = <PrefOption>[
  ('dating', 'Dating'),
  ('serious', 'Serious'),
  ('casual', 'Casual'),
];

/// Own rashi, including "Don't know".
const profileRashiOptions = <PrefOption>[...prefRashiOptions, ('unknown', "Don't know")];

const _vedicGotras = [
  'Agastya', 'Angiras', 'Atreya', 'Atri', 'Bharadwaj', 'Bhrigu', 'Dhananjaya', 'Garg', 'Gautam',
  'Ghritakaushik', 'Harit', 'Jamadagni', 'Kapil', 'Kashyap', 'Katyayan', 'Kaundinya', 'Kaushik',
  'Kutsa', 'Maitreya', 'Mandavya', 'Maudgalya', 'Parashar', 'Sandilya', 'Savarna', 'Shrivatsa',
  'Upamanyu', 'Vashistha', 'Vatsa', 'Vishwamitra',
];

const _marwadiGotras = [
  'Agarwal (Garg)', 'Bansal', 'Goyal', 'Kansal', 'Mittal', 'Singhal', 'Tayal', 'Jindal',
  'Bhandari', 'Chordia', 'Kothari', 'Lodha', 'Surana', 'Maheshwari', ..._vedicGotras,
];

const _clans = <String, (String, List<String>)>{
  'Bahun': ('Sub-group', ['Upadhyaya (Purbiya)', 'Kumai', 'Jaisi', 'Rajopadhyaya', 'Other']),
  'Chhetri': ('Thar (surname group)', [
    'Adhikari', 'Basnet', 'Bhandari', 'Bista', 'Bohara', 'Budhathoki', 'Karki',
    'Khadka', 'Khatri', 'Kunwar', 'Rawal', 'Rana', 'Rokaya', 'Thapa', 'Other',
  ]),
  'Thakuri': ('Thar (clan)', ['Shah', 'Malla', 'Chand', 'Singh', 'Sen', 'Hamal', 'Rathaur', 'Kalyal', 'Other']),
  'Newar': ('Newar caste', [
    'Rajopadhyaya', 'Bajracharya', 'Shakya', 'Joshi', 'Karmacharya', 'Shrestha',
    'Pradhan', 'Amatya', 'Malla', 'Tuladhar', 'Kansakar', 'Maharjan', 'Dangol',
    'Manandhar', 'Tamrakar', 'Awale', 'Chitrakar', 'Nakarmi', 'Ranjitkar',
    'Khadgi', 'Kapali', 'Other',
  ]),
  'Gurung': ('Clan (Char jat / Sora jat)', [
    'Ghale', 'Ghotane', 'Lamichhane', 'Lama', 'Plon', 'Kromchhain', 'Tamu (other)', 'Other',
  ]),
  'Magar': ('Clan', ['Ale', 'Budha', 'Gharti', 'Pun', 'Rana', 'Roka', 'Thapa', 'Jhankri', 'Other']),
  'Tamang': ('Clan', [
    'Moktan', 'Yonjan', 'Lopchan', 'Waiba', 'Ghising', 'Bomjan', 'Syangtan',
    'Thokar', 'Titung', 'Pakhrin', 'Dong', 'Blon', 'Gole', 'Other',
  ]),
  'Sherpa': ('Clan (ru)', [
    'Salaka', 'Goparma', 'Chiawa', 'Pinasa', 'Thimmi', 'Paldorje', 'Lhukpa',
    'Gardza', 'Mendewa', 'Khambadze', 'Other',
  ]),
  'Thakali': ('Clan', ['Gauchan', 'Tulachan', 'Sherchan', 'Bhattachan', 'Other']),
  'Rai': ('Rai group', [
    'Bantawa', 'Chamling', 'Kulung', 'Thulung', 'Sampang', 'Khaling', 'Dumi',
    'Bahing', 'Yamphu', 'Mewahang', 'Lohorung', 'Nachhiring', 'Athpahariya', 'Other',
  ]),
  'Limbu': ('Thum (region)', [
    'Panthare', 'Tamarkhole', 'Phedappe', 'Chhathare', 'Yangwarok', 'Mewakhola',
    'Maiwakhola', 'Chaubise', 'Other',
  ]),
  'Tharu': ('Tharu group', ['Rana', 'Dangaura', 'Kathariya', 'Kochila', 'Chitwaniya', 'Other']),
  'Brahmin (Madhesi)': ('Sub-group', ['Maithil', 'Kanyakubja', 'Bhumihar', 'Other']),
  'Muslim': ('Community', ['Madhesi Muslim', 'Churaute (Hill Muslim)', 'Kashmiri', 'Tibetan Muslim', 'Other']),
};

/// Castes that keep a Vedic gotra; Janajati and Kirat groups use clans instead.
final Set<String> _gotraCastes = {
  ..._hillHighCastes,
  'Newar',
  ..._madhesiCastes.where((c) => c != 'Tharu' && c != 'Rajbanshi'),
  ..._dalitCastes,
  'Marwadi',
  'Baniya',
};

/// Sub-caste or clan list for a caste, with the label to show above it.
(String label, List<String> options)? subCasteFor(String? caste) =>
    caste == null || caste.isEmpty ? null : _clans[caste];

/// Gotra list for a religion + caste, or null when gotra doesn't apply.
List<String>? gotraOptionsFor(String? religion, String? caste) {
  final key = toReligionKey(religion);
  if (caste == null || caste.isEmpty || !const ['hindu', 'buddhist', 'jain'].contains(key)) return null;
  if (!_gotraCastes.contains(caste)) return null;
  if (key == 'buddhist' && caste != 'Newar') return null; // Only Newars keep one.
  final list = caste == 'Marwadi' || caste == 'Baniya' ? _marwadiGotras : _vedicGotras;
  return [...list, "Don't know"];
}

/// Clear answers that no longer apply after religion or caste changes.
({String caste, String subCaste, String gotra}) reconcileBackground({
  required String religion,
  required String caste,
  required String subCaste,
  required String gotra,
}) {
  final castes = casteOptionsFor(religion);
  final nextCaste = castes.contains(caste) ? caste : (castes.length == 1 ? castes.first : '');
  final sub = subCasteFor(nextCaste);
  final nextSub = sub != null && sub.$2.contains(subCaste) ? subCaste : '';
  final gotras = gotraOptionsFor(religion, nextCaste);
  final nextGotra = gotras != null && gotras.contains(gotra) ? gotra : '';
  return (caste: nextCaste, subCaste: nextSub, gotra: nextGotra);
}

// --- Lifestyle tags (LifestyleFields.tsx) ------------------------------------
// Stored in `lifestyle_tags`: bare personality / lifestyle / interest values
// plus `smoking:x`, `drinking:x`, `exercise:x`. Other tags are kept as-is.

enum LifestyleGroup { personality, lifestyle, interests, smoking, drinking, exercise }

final List<String> allInterestOptions = [for (final g in prefInterestGroups) ...g.$2];

List<PrefOption> _bareOptions(LifestyleGroup g) => switch (g) {
      LifestyleGroup.personality => prefPersonalityOptions,
      LifestyleGroup.lifestyle => prefLifestyleOptions,
      LifestyleGroup.interests => [for (final i in allInterestOptions) (i, i)],
      _ => const [],
    };

List<PrefOption> _prefixOptions(LifestyleGroup g) => switch (g) {
      LifestyleGroup.smoking || LifestyleGroup.drinking => prefFrequencyOptions,
      LifestyleGroup.exercise => prefExerciseOptions,
      _ => const [],
    };

bool _isPrefix(LifestyleGroup g) =>
    g == LifestyleGroup.smoking || g == LifestyleGroup.drinking || g == LifestyleGroup.exercise;

List<String> parseLifestyleTags(String text) {
  final seen = <String>{};
  return text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty && seen.add(t.toLowerCase()))
      .toList();
}

String? _match(String tag, LifestyleGroup g) {
  final lower = tag.toLowerCase();
  if (_isPrefix(g)) {
    final prefix = '${g.name}:';
    if (!lower.startsWith(prefix)) return null;
    final value = lower.substring(prefix.length);
    return _prefixOptions(g).any((o) => o.$1 == value) ? value : null;
  }
  for (final o in _bareOptions(g)) {
    if (o.$1.toLowerCase() == lower) return o.$1;
  }
  return null;
}

LifestyleGroup? _groupOf(String tag) {
  for (final g in LifestyleGroup.values.where(_isPrefix)) {
    if (_match(tag, g) != null) return g;
  }
  for (final g in LifestyleGroup.values.where((g) => !_isPrefix(g))) {
    if (_match(tag, g) != null) return g;
  }
  return null;
}

/// Values selected in [group] from the comma-separated tags text.
List<String> lifestyleSelected(String text, LifestyleGroup group) =>
    parseLifestyleTags(text).map((t) => _match(t, group)).whereType<String>().toList();

/// Replace one group's values, keeping every other tag.
String setLifestyleGroup(String text, LifestyleGroup group, List<String> next) {
  final kept = parseLifestyleTags(text).where((t) => _groupOf(t) != group);
  final added = _isPrefix(group) ? next.map((v) => '${group.name}:$v') : next;
  return [...kept, ...added].join(', ');
}

/// Human-readable label for a stored tag, e.g. "smoking:no" -> "Smoking: No".
String formatLifestyleTagLabel(String tag) {
  for (final g in LifestyleGroup.values.where(_isPrefix)) {
    final value = _match(tag, g);
    if (value != null) {
      final label = _prefixOptions(g).firstWhere((o) => o.$1 == value, orElse: () => (value, value)).$2;
      return '${g.name[0].toUpperCase()}${g.name.substring(1)}: $label';
    }
  }
  for (final g in LifestyleGroup.values.where((g) => !_isPrefix(g))) {
    final value = _match(tag, g);
    if (value != null) return _bareOptions(g).firstWhere((o) => o.$1 == value).$2;
  }
  final parts = tag.split(':');
  if (parts.length > 1 && parts.first.isNotEmpty) {
    return '${parts.first[0].toUpperCase()}${parts.first.substring(1)}: ${parts.sublist(1).join(':').replaceAll('_', ' ')}';
  }
  return tag;
}
