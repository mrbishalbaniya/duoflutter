class DuoOption<T extends String> {
  const DuoOption({required this.value, required this.label});

  final T value;
  final String label;
}

const nepalProvinces = [
  'Koshi',
  'Madhesh',
  'Bagmati',
  'Gandaki',
  'Lumbini',
  'Karnali',
  'Sudurpashchim',
];

const genderOptions = [
  DuoOption(value: 'male', label: 'Male'),
  DuoOption(value: 'female', label: 'Female'),
  DuoOption(value: 'other', label: 'Other'),
];

const maritalStatusOptions = [
  DuoOption(value: 'never_married', label: 'Never Married'),
  DuoOption(value: 'divorced', label: 'Divorced'),
  DuoOption(value: 'widowed', label: 'Widowed'),
];

const relationshipGoalOptions = [
  DuoOption(value: 'dating', label: 'Dating'),
  DuoOption(value: 'serious', label: 'Serious Relationship'),
  DuoOption(value: 'marriage', label: 'Marriage'),
  DuoOption(value: 'friendship', label: 'Friendship'),
];

const educationLevelOptions = [
  DuoOption(value: 'see', label: 'SEE'),
  DuoOption(value: 'plus_two', label: '+2'),
  DuoOption(value: 'diploma', label: 'Diploma'),
  DuoOption(value: 'bachelor', label: 'Bachelor'),
  DuoOption(value: 'master', label: 'Master'),
  DuoOption(value: 'phd', label: 'PhD'),
];

const fieldOfStudyOptions = [
  DuoOption(value: 'it', label: 'IT'),
  DuoOption(value: 'engineering', label: 'Engineering'),
  DuoOption(value: 'medical', label: 'Medical'),
  DuoOption(value: 'business', label: 'Business'),
  DuoOption(value: 'law', label: 'Law'),
  DuoOption(value: 'arts', label: 'Arts'),
  DuoOption(value: 'agriculture', label: 'Agriculture'),
  DuoOption(value: 'other', label: 'Other'),
];

const employmentOptions = [
  DuoOption(value: 'student', label: 'Student'),
  DuoOption(value: 'employed', label: 'Employed'),
  DuoOption(value: 'self_employed', label: 'Self-employed'),
  DuoOption(value: 'freelancer', label: 'Freelancer'),
  DuoOption(value: 'business_owner', label: 'Business Owner'),
  DuoOption(value: 'unemployed', label: 'Unemployed'),
];

const incomeOptions = [
  DuoOption(value: 'below_20k', label: 'Below NPR 20,000'),
  DuoOption(value: '20k_50k', label: 'NPR 20,000 - 50,000'),
  DuoOption(value: '50k_100k', label: 'NPR 50,000 - 100,000'),
  DuoOption(value: '100k_200k', label: 'NPR 100,000 - 200,000'),
  DuoOption(value: '200k_plus', label: 'NPR 200,000+'),
];

const religionOptions = [
  DuoOption(value: 'hindu', label: 'Hindu'),
  DuoOption(value: 'buddhist', label: 'Buddhist'),
  DuoOption(value: 'muslim', label: 'Muslim'),
  DuoOption(value: 'christian', label: 'Christian'),
  DuoOption(value: 'kirat', label: 'Kirat'),
  DuoOption(value: 'other', label: 'Other'),
];

const casteOptions = [
  'Bahun',
  'Chhetri',
  'Thakuri',
  'Newar',
  'Gurung',
  'Magar',
  'Rai',
  'Limbu',
  'Tamang',
  'Sherpa',
  'Tharu',
  'Sunuwar',
  'Yadav',
  'Kami',
  'Damai',
  'Sarki',
  'Other',
];

const gotraOptions = [
  'Bharadwaj',
  'Kashyap',
  'Gautam',
  'Kaushik',
  'Vashistha',
  'Atri',
  'Agastya',
  'Jamadagni',
  'Sandilya',
  'Angiras',
  'Unknown',
];

const horoscopeOptions = [
  DuoOption(value: 'required', label: 'Required'),
  DuoOption(value: 'not_required', label: 'Not Required'),
];

const personalityOptions = [
  DuoOption(value: 'introvert', label: 'Introvert'),
  DuoOption(value: 'ambivert', label: 'Ambivert'),
  DuoOption(value: 'extrovert', label: 'Extrovert'),
];

const lifestyleOptions = [
  DuoOption(value: 'active', label: 'Active'),
  DuoOption(value: 'balanced', label: 'Balanced'),
  DuoOption(value: 'relaxed', label: 'Relaxed'),
];

const frequencyOptions = [
  DuoOption(value: 'no', label: 'No'),
  DuoOption(value: 'occasionally', label: 'Occasionally'),
  DuoOption(value: 'yes', label: 'Yes'),
];

const exerciseOptions = [
  DuoOption(value: 'gym', label: 'Gym'),
  DuoOption(value: 'yoga', label: 'Yoga'),
  DuoOption(value: 'sports', label: 'Sports'),
  DuoOption(value: 'running', label: 'Running'),
  DuoOption(value: 'none', label: 'None'),
];

const interestOptions = [
  'Trekking',
  'Hiking',
  'Travel',
  'Photography',
  'Movies',
  'Music',
  'Cricket',
  'Football',
  'Coding',
  'Reading',
  'Business',
  'Technology',
  'Fitness',
  'Cooking',
  'Art',
  'Nature',
  'Volunteering',
  'Spirituality',
];

const lookingForOptions = [
  DuoOption(value: 'male', label: 'Male'),
  DuoOption(value: 'female', label: 'Female'),
  DuoOption(value: 'everyone', label: 'Everyone'),
];

const distanceOptions = [
  DuoOption(value: '5', label: '5 KM'),
  DuoOption(value: '10', label: '10 KM'),
  DuoOption(value: '25', label: '25 KM'),
  DuoOption(value: '50', label: '50 KM'),
  DuoOption(value: 'anywhere', label: 'Anywhere in Nepal'),
];

const marriagePrefOptions = [
  DuoOption(value: 'yes', label: 'Yes'),
  DuoOption(value: 'no', label: 'No'),
  DuoOption(value: 'depends', label: 'Depends'),
];

const heightFeetOptions = [4, 5, 6, 7];
const heightInchesOptions = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

String labelForOption<T extends String>(List<DuoOption<T>> options, String value) {
  for (final option in options) {
    if (option.value == value) return option.label;
  }
  return value.isEmpty ? '—' : value;
}
