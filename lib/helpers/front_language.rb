class FrontLanguage
  HASH =
    { ar: 'Arabic',
      'zh-CN': 'Chinese (simplified)',
      cs: 'Czech',
      da: 'Danish',
      nl: 'Dutch',
      en: 'English',
      fi: 'Finnish',
      fr: 'French',
      de: 'German',
      he: 'Hebrew',
      hi: 'Hindi',
      ka: 'Georgian',
      hu: 'Hungarian',
      id: 'Indonesian',
      it: 'Italian',
      ja: 'Japanese',
      ko: 'Korean',
      no: 'Norwegian',
      pl: 'Polish',
      'pt-BR': 'Portuguese - Brazil',
      ro: 'Romanian',
      ru: 'Russian',
      sk: 'Slovak',
      es: 'Spanish',
      sv: 'Swedish',
      tr: 'Turkish',
      uk: 'Ukrainian'
    }.freeze

  def self.list
    HASH.invert.to_a
  end

  def self.supports?(locale)
    return false if locale.blank?
    HASH.with_indifferent_access.key?(locale)
  end

  def self.keys
    HASH.keys
  end
end
