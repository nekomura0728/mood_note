// Language translations
const translations = {
    ja: {
        appName: "😌 きぶん日記",
        langButton: "English",
        title: "きぶん日記",
        subtitle: "毎日の気分を記録して、心の健康をサポートするiOSアプリ",
        featuresTitle: "アプリの特徴",
        feature1Title: "簡単な気分記録",
        feature1Desc: "5つの気分で日々の感情を素早く記録",
        feature2Title: "統計・分析",
        feature2Desc: "気分の変化をグラフで可視化",
        feature3Title: "プライバシー重視",
        feature3Desc: "データは端末内にのみ保存",
        proTitle: "Pro版機能",
        proBadge: "Pro版限定",
        proDesc: "AIによるパーソナルコーチングと詳細な分析機能",
        proFeature1: "パーソナルコーチング - 気分パターンを分析してアドバイス",
        proFeature2: "詳細レポート - 長期間の傾向を詳細に分析",
        priceText: "¥300",
        priceNote: "買い切り価格",
        contactTitle: "お問い合わせ",
        privacyLink: "プライバシーポリシー",
        footer: "© 2025 きぶん日記. All rights reserved.",
        // Privacy page
        privacyTitle: "プライバシーポリシー",
        backButton: "← 戻る",
        privacyIntro: "きぶん日記は、ユーザーのプライバシーを最優先に考えています。",
        dataTitle: "収集するデータ",
        dataDesc: "気分記録データ、メモ、通知設定のみを収集します。",
        storageTitle: "データの保存",
        storageDesc: "すべてのデータはユーザーのデバイス内にのみ保存され、外部サーバーに送信されることはありません。",
        thirdPartyTitle: "第三者への提供",
        thirdPartyDesc: "法令に基づく場合を除き、個人情報を第三者に提供することはありません。"
    },
    en: {
        appName: "😌 Mood Journal",
        langButton: "日本語",
        title: "Mood Journal",
        subtitle: "Track your daily mood and support your mental health with AI coaching",
        featuresTitle: "Key Features",
        feature1Title: "Easy Mood Tracking",
        feature1Desc: "Quickly record emotions with 5 mood options",
        feature2Title: "Statistics & Analysis",
        feature2Desc: "Visualize mood changes with charts",
        feature3Title: "Privacy First",
        feature3Desc: "All data stored locally on your device",
        proTitle: "Pro Features",
        proBadge: "Pro Only",
        proDesc: "AI-powered personal coaching and detailed analytics",
        proFeature1: "Personal Coaching - Analyze mood patterns and provide advice",
        proFeature2: "Detailed Reports - Long-term trend analysis",
        priceText: "$2.99",
        priceNote: "One-time purchase",
        contactTitle: "Contact",
        privacyLink: "Privacy Policy",
        footer: "© 2025 Mood Journal. All rights reserved.",
        // Privacy page
        privacyTitle: "Privacy Policy",
        backButton: "← Back",
        privacyIntro: "Mood Journal prioritizes user privacy above all else.",
        dataTitle: "Data Collection",
        dataDesc: "We only collect mood records, notes, and notification settings.",
        storageTitle: "Data Storage",
        storageDesc: "All data is stored locally on your device only and is never sent to external servers.",
        thirdPartyTitle: "Third Party Sharing",
        thirdPartyDesc: "We do not share personal information with third parties except as required by law."
    }
};

let currentLang = 'ja';

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    setupLanguageToggle();
    updateContent();
});

function setupLanguageToggle() {
    const button = document.querySelector('.language-toggle');
    if (button) {
        button.addEventListener('click', toggleLanguage);
    }
}

function toggleLanguage() {
    currentLang = currentLang === 'ja' ? 'en' : 'ja';
    updateContent();
    localStorage.setItem('mood-journal-lang', currentLang);
}

function updateContent() {
    const texts = translations[currentLang];
    
    // Update all text content
    updateText('.logo', texts.appName);
    updateText('.language-toggle', texts.langButton);
    updateText('h1', texts.title);
    updateText('.subtitle', texts.subtitle);
    updateText('#features-title', texts.featuresTitle);
    updateText('#feature1-title', texts.feature1Title);
    updateText('#feature1-desc', texts.feature1Desc);
    updateText('#feature2-title', texts.feature2Title);
    updateText('#feature2-desc', texts.feature2Desc);
    updateText('#feature3-title', texts.feature3Title);
    updateText('#feature3-desc', texts.feature3Desc);
    updateText('#pro-title', texts.proTitle);
    updateText('.pro-badge', texts.proBadge);
    updateText('#pro-desc', texts.proDesc);
    updateText('#pro-feature1', texts.proFeature1);
    updateText('#pro-feature2', texts.proFeature2);
    updateText('.price', texts.priceText);
    updateText('.price-note', texts.priceNote);
    updateText('#contact-title', texts.contactTitle);
    updateText('.privacy-link a', texts.privacyLink);
    updateText('.footer', texts.footer);
    
    // Privacy page specific
    updateText('.privacy-title', texts.privacyTitle);
    updateText('.back-button', texts.backButton);
    updateText('.privacy-intro', texts.privacyIntro);
    updateText('.data-title', texts.dataTitle);
    updateText('.data-desc', texts.dataDesc);
    updateText('.storage-title', texts.storageTitle);
    updateText('.storage-desc', texts.storageDesc);
    updateText('.thirdparty-title', texts.thirdPartyTitle);
    updateText('.thirdparty-desc', texts.thirdPartyDesc);
}

function updateText(selector, text) {
    const element = document.querySelector(selector);
    if (element && text) {
        element.textContent = text;
    }
}

// Load saved language
const savedLang = localStorage.getItem('mood-journal-lang');
if (savedLang) {
    currentLang = savedLang;
}