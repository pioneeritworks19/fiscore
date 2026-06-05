import { useState } from 'react';
import type { User } from 'firebase/auth';
import { useTranslation } from 'react-i18next';
import { Globe2 } from 'lucide-react';
import { updateLanguagePreference } from '../../data';
import type { UserProfile } from '../../types';
import i18n from '../../shared/i18n/i18n';

export function SettingsPage({ user, profile }: { user: User; profile: UserProfile | null }) {
  const { t } = useTranslation();
  const [language, setLanguage] = useState<'en' | 'es'>((profile?.languagePreference || i18n.language || 'en').startsWith('es') ? 'es' : 'en');
  const [message, setMessage] = useState<string | null>(null);

  async function save() {
    await updateLanguagePreference(user.uid, language);
    await i18n.changeLanguage(language);
    setMessage(t('languageSaved'));
  }

  return (
    <section className="panel narrow">
      <h2>{t('settings')}</h2>
      <label className="field">
        <span>{t('language')}</span>
        <select value={language} onChange={(event) => setLanguage(event.target.value as 'en' | 'es')}>
          <option value="en">{t('english')}</option>
          <option value="es">{t('spanish')}</option>
        </select>
      </label>
      <button className="button primary" onClick={save}>
        <Globe2 size={18} />
        {t('saveLanguage')}
      </button>
      {message && <div className="status success">{message}</div>}
    </section>
  );
}
