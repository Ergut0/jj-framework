export const Rarity: Record<string, { text: string; background: string }> = {
    common: { text: '#ffffff', background: 'radial-gradient(#00000050, #51515150)' },
    uncommon: { text: '#84cc16', background: 'radial-gradient(#00000050, #84cc1610)' },
    rare: { text: '#0ea5e9', background: 'radial-gradient(#00000000, #0ea5e920)' },
    epic: { text: '#c026d3', background: 'radial-gradient(#00000000, #be185d25)' },
    legendary: { text: '#eab308', background: 'radial-gradient(#00000000, #a1620725)' },
};

export const normalizeRarity = (value: unknown): string | undefined => {
    if (typeof value === 'string') {
        const trimmed = value.trim();

        return trimmed ? trimmed.toLowerCase() : undefined;
    }

    if (typeof value === 'number' && Number.isFinite(value)) return String(value);

    return undefined;
};

let enabled = true;

export const setRarityEnabled = (value: boolean) => {
    enabled = value;
};

export const isRarityEnabled = () => enabled;
