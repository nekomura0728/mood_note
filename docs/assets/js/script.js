// Language data
const translations = {
    ja: {
        // Header
        appName: "きぶん日記",
        languageToggle: "English",
        
        // Main content
        title: "きぶん日記",
        subtitle: "毎日の気分を記録して、心の健康をサポートするiOSアプリ",
        
        // Features
        featuresTitle: "アプリの特徴",
        feature1Title: "簡単な気分記録",
        feature1Desc: "5つの気分で日々の感情を素早く記録",
        feature2Title: "統計・分析",
        feature2Desc: "気分の変化をグラフで可視化",
        feature3Title: "プライバシー重視",
        feature3Desc: "データは端末内にのみ保存",
        
        // Pro features
        proTitle: "Pro版機能",
        proBadge: "Pro版限定",
        proDesc: "AIによるパーソナルコーチングと詳細な分析機能",
        proFeature1: "パーソナルコーチング - 気分パターンを分析してアドバイス",
        proFeature2: "詳細レポート - 長期間の傾向を詳細に分析",
        priceAmount: "¥300",
        priceNote: "買い切り価格",
        
        // Contact
        contactTitle: "お問い合わせ",
        privacyLink: "プライバシーポリシー",
        footer: "© 2025 きぶん日記. All rights reserved."
    },
    en: {
        // Header
        appName: "Mood Journal",
        languageToggle: "日本語",
        
        // Main content
        title: "Mood Journal",
        subtitle: "Track your daily mood and support your mental health with AI coaching",
        
        // Features
        featuresTitle: "Key Features",
        feature1Title: "Easy Mood Tracking",
        feature1Desc: "Quickly record emotions with 5 mood options",
        feature2Title: "Statistics & Analysis",
        feature2Desc: "Visualize mood changes with charts",
        feature3Title: "Privacy First",
        feature3Desc: "All data stored locally on your device",
        
        // Pro features
        proTitle: "Pro Features",
        proBadge: "Pro Only",
        proDesc: "AI-powered personal coaching and detailed analytics",
        proFeature1: "Personal Coaching - Analyze mood patterns and provide advice",
        proFeature2: "Detailed Reports - Long-term trend analysis",
        priceAmount: "$2.99",
        priceNote: "One-time purchase",
        
        // Contact
        contactTitle: "Contact",
        privacyLink: "Privacy Policy",
        footer: "© 2025 Mood Journal. All rights reserved."
    }
};

// Privacy policy translations
const privacyTranslations = {
    ja: {
        title: "プライバシーポリシー",
        backButton: "← 戻る",
        lastUpdated: "最終更新日: 2025年8月24日",
        intro: "きぶん日記は、ユーザーのプライバシーを最優先に考えています。",
        dataCollection: "収集するデータ",
        dataCollectionDesc: "• 気分記録データ（気分の種類、記録日時）<br>• メモやコメント（任意）<br>• 通知設定",
        dataUsage: "データの利用",
        dataUsageDesc: "収集したデータは気分の分析・表示、アプリの改善にのみ利用されます。",
        dataStorage: "データの保存",
        dataStorageDesc: "すべてのデータはユーザーのデバイス内にのみ保存され、外部サーバーに送信されることはありません。",
        thirdParty: "第三者への提供",
        thirdPartyDesc: "法令に基づく場合を除き、個人情報を第三者に提供することはありません。",
        contact: "お問い合わせ",
        contactDesc: "ご質問がございましたら、以下までお問い合わせください：",
        contactEmail: "nekomura@liz-aria.com"
    },
    en: {
        title: "Privacy Policy",
        backButton: "← Back",
        lastUpdated: "Last updated: August 24, 2025",
        intro: "Mood Journal prioritizes user privacy above all else.",
        dataCollection: "Data Collection",
        dataCollectionDesc: "• Mood record data (mood type, timestamp)<br>• Notes and comments (optional)<br>• Notification settings",
        dataUsage: "Data Usage",
        dataUsageDesc: "Collected data is used only for mood analysis, display, and app improvement.",
        dataStorage: "Data Storage",
        dataStorageDesc: "All data is stored locally on your device only and is never sent to external servers.",
        thirdParty: "Third Party Sharing",
        thirdPartyDesc: "We do not share personal information with third parties except as required by law.",
        contact: "Contact",
        contactDesc: "If you have any questions, please contact us at:",
        contactEmail: "nekomura@liz-aria.com"
    }
};

// Current language
let currentLanguage = 'ja';

// DOM elements cache
let elements = {};

// Initialize the app
document.addEventListener('DOMContentLoaded', function() {
    cacheElements();
    setupLanguageToggle();
    updateContent();
    setupBackButton();
});

// Cache DOM elements
function cacheElements() {
    // Main page elements
    elements = {
        languageToggle: document.querySelector('.language-toggle'),
        appName: document.querySelector('[data-key="appName"]'),
        title: document.querySelector('[data-key="title"]'),
        subtitle: document.querySelector('[data-key="subtitle"]'),
        featuresTitle: document.querySelector('[data-key="featuresTitle"]'),
        proTitle: document.querySelector('[data-key="proTitle"]'),
        proBadge: document.querySelector('[data-key="proBadge"]'),
        proDesc: document.querySelector('[data-key="proDesc"]'),
        priceAmount: document.querySelector('[data-key="priceAmount"]'),
        priceNote: document.querySelector('[data-key="priceNote"]'),
        contactTitle: document.querySelector('[data-key="contactTitle"]'),
        privacyLink: document.querySelector('[data-key="privacyLink"]'),
        footer: document.querySelector('[data-key="footer"]'),
        contactEmail: document.querySelector('.contact-email')
    };
    
    // Feature elements
    for (let i = 1; i <= 3; i++) {
        elements[`feature${i}Title`] = document.querySelector(`[data-key="feature${i}Title"]`);
        elements[`feature${i}Desc`] = document.querySelector(`[data-key="feature${i}Desc"]`);
    }
    
    // Pro feature elements
    for (let i = 1; i <= 2; i++) {
        elements[`proFeature${i}`] = document.querySelector(`[data-key="proFeature${i}"]`);
    }
    
    // Privacy page elements
    const privacyElements = [
        'privacyTitle', 'backButton', 'lastUpdated', 'intro', 
        'dataCollection', 'dataCollectionDesc', 'dataUsage', 'dataUsageDesc',
        'dataStorage', 'dataStorageDesc', 'thirdParty', 'thirdPartyDesc',
        'privacyContact', 'contactDesc', 'privacyContactEmail'
    ];
    
    privacyElements.forEach(key => {
        const element = document.querySelector(`[data-key="${key}"]`);
        if (element) elements[key] = element;
    });
}

// Setup language toggle
function setupLanguageToggle() {
    const toggle = elements.languageToggle;
    if (toggle) {
        toggle.addEventListener('click', toggleLanguage);
    }
}

// Toggle language
function toggleLanguage() {
    currentLanguage = currentLanguage === 'ja' ? 'en' : 'ja';
    updateContent();
    
    // Save to localStorage
    localStorage.setItem('mood-journal-language', currentLanguage);
}

// Update content based on current language
function updateContent() {
    const isPrivacyPage = window.location.pathname.includes('privacy.html');
    const data = isPrivacyPage ? privacyTranslations[currentLanguage] : translations[currentLanguage];
    
    // Update language toggle button
    if (elements.languageToggle) {
        elements.languageToggle.textContent = translations[currentLanguage].languageToggle;
    }
    
    // Update content
    Object.keys(data).forEach(key => {
        const element = elements[key];
        if (element) {
            if (key.includes('Desc') || key === 'contactDesc') {
                element.innerHTML = data[key];
            } else {
                element.textContent = data[key];
            }
        }
    });
    
    // Update contact email
    if (elements.contactEmail) {
        elements.contactEmail.href = `mailto:${isPrivacyPage ? data.contactEmail : 'nekomura@liz-aria.com'}`;
        elements.contactEmail.textContent = isPrivacyPage ? data.contactEmail : 'nekomura@liz-aria.com';
    }
    
    // Update privacy contact email
    if (elements.privacyContactEmail) {
        elements.privacyContactEmail.href = `mailto:${data.privacyContactEmail || data.contactEmail}`;
        elements.privacyContactEmail.textContent = data.privacyContactEmail || data.contactEmail;
    }
}

// Setup back button for privacy page
function setupBackButton() {
    const backButton = document.querySelector('.back-button');
    if (backButton) {
        backButton.addEventListener('click', function(e) {
            e.preventDefault();
            window.history.back();
        });
    }
}

// Load saved language preference
window.addEventListener('load', function() {
    const savedLanguage = localStorage.getItem('mood-journal-language');
    if (savedLanguage && savedLanguage !== currentLanguage) {
        currentLanguage = savedLanguage;
        updateContent();
    }
});