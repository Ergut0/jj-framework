import { createContext, useContext } from "react";
import type { Locale } from "./types";
import core from "./locales/core";
import player from "./locales/player";
import admin from "./locales/admin";
import hud from "./locales/hud";

export type Dict = Record<string, string>;
export type Translator = (key: string, vars?: Record<string, string | number>) => string;

const dictionaries: Record<Locale, Dict> = {
  es: { ...core.es, ...player.es, ...admin.es, ...hud.es },
  en: { ...core.en, ...player.en, ...admin.en, ...hud.en },
};

/** Traduccion con interpolacion {var} y fallback a ingles y a la propia clave */
export function makeT(locale: Locale): Translator {
  return (key, vars) => {
    let str = dictionaries[locale]?.[key] ?? dictionaries.en[key] ?? key;
    if (vars) for (const [k, v] of Object.entries(vars)) str = str.replaceAll(`{${k}}`, String(v));
    return str;
  };
}

export const I18nContext = createContext<Translator>(makeT("es"));
export const useT = () => useContext(I18nContext);
