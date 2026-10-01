// Generated from DuoFrontend/messages/en/settingsExtra.json. Keep in sync with the web app.

class FaqEntry {
  const FaqEntry(this.question, this.answer);
  final String question;
  final String answer;
}

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final List<String> body;
}

class LegalDocument {
  const LegalDocument({required this.title, required this.updatedLabel, required this.intro, required this.sections});
  final String title;
  final String updatedLabel;
  final String intro;
  final List<LegalSection> sections;
}

class HelpGuide {
  const HelpGuide(this.title, this.description);
  final String title;
  final String description;
}

const faqEntries = <FaqEntry>[
  FaqEntry("How do I create a match?", "Swipe right on profiles you're interested in. If they swipe right too, it's a match!"),
  FaqEntry("How do I edit my profile?", "Go to Settings > Edit Profile to update your photos, bio, and preferences."),
  FaqEntry("How does the wallet and coins system work?", "Coins can be purchased with real money via eSewa and used to unlock premium features."),
  FaqEntry("How do I report or block someone?", "Open their profile and tap the menu icon, then choose Report or Block."),
  FaqEntry("How do I delete my account?", "Go to Settings > Account and select Delete Account. This action is permanent."),
  FaqEntry("How do I verify my profile?", "Go to Settings > Verification and follow the steps to take a verification selfie."),
  FaqEntry("Is my payment information secure?", "Yes, all payments are processed securely through eSewa. We never store your payment credentials."),
];

const helpGuides = <HelpGuide>[
  HelpGuide("Getting Started with Matching", "Tips for creating a great profile and finding matches"),
  HelpGuide("Messaging Safely", "Best practices for chatting with your matches"),
  HelpGuide("Staying Safe on Duo", "Learn how to protect your privacy and report concerns"),
  HelpGuide("Coins & Payments", "How to buy and use Duo Coins"),
];

const privacyDocument = LegalDocument(
  title: "Privacy Policy",
  updatedLabel: "Last updated: January 2026",
  intro: "This Privacy Policy explains how Duo collects, uses, and protects your information.",
  sections: [
    LegalSection("Information We Collect", [
      "We collect information you provide directly, such as your profile details, photos, and messages.",
      "We also collect usage data and device information to improve our service.",
    ]),
    LegalSection("How We Use Information", [
      "We use your information to provide matchmaking, personalize your experience, and ensure safety.",
      "We may use aggregated data for analytics and product improvement.",
    ]),
    LegalSection("Sharing Information", [
      "We do not sell your personal data.",
      "We may share information with service providers who help us operate Duo, and as required by law.",
    ]),
    LegalSection("Your Choices & Rights", [
      "You can access, update, or delete your account information from Settings.",
      "You may contact us to request a copy of your data.",
    ]),
    LegalSection("Data Retention & Security", [
      "We retain your data as long as your account is active or as needed to comply with legal obligations.",
      "We use industry-standard measures to protect your data.",
    ]),
    LegalSection("Changes to This Policy", [
      "We may update this Privacy Policy periodically. We will notify you of significant changes.",
    ]),
    LegalSection("Contact Us", [
      "If you have questions about this policy, contact us at privacy@duo.app.",
    ]),
  ],
);

const termsDocument = LegalDocument(
  title: "Terms of Service",
  updatedLabel: "Last updated: January 2026",
  intro: "By using Duo, you agree to the following terms. Please read them carefully.",
  sections: [
    LegalSection("Eligibility", [
      "You must be at least 18 years old to use Duo.",
      "By creating an account, you represent that all information you provide is accurate and truthful.",
    ]),
    LegalSection("Your Account", [
      "You are responsible for maintaining the confidentiality of your account credentials.",
      "You agree to notify us immediately of any unauthorized use of your account.",
    ]),
    LegalSection("Community Standards", [
      "Treat other members with respect. Harassment, hate speech, and abusive behavior are not tolerated.",
      "We reserve the right to remove content or suspend accounts that violate these standards.",
    ]),
    LegalSection("Coins & Premium Payments", [
      "Duo Coins and premium subscriptions are purchased through our supported payment methods, including eSewa.",
      "All purchases are final except where required by law.",
    ]),
    LegalSection("Safety", [
      "Never share personal financial information with other members.",
      "Report suspicious behavior immediately through the app.",
    ]),
    LegalSection("Account Termination", [
      "We may suspend or terminate accounts that violate these Terms.",
      "You may delete your account at any time from Settings.",
    ]),
    LegalSection("Disclaimers & Liability", [
      "Duo is provided \"as is\" without warranties of any kind.",
      "We are not liable for interactions between users that occur outside the platform.",
    ]),
    LegalSection("Changes to These Terms", [
      "We may update these Terms from time to time. Continued use of Duo constitutes acceptance of the revised Terms.",
    ]),
    LegalSection("Contact Us", [
      "If you have questions about these Terms, contact us at support@duo.app.",
    ]),
  ],
);
