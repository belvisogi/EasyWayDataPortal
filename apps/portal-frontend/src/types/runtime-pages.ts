export type ActionSpec =
    | { type: 'link'; href: string }
    | { type: 'noop' };

export type CtaSpec = {
    labelKey: string;
    action: ActionSpec;
};

export type HeroSection = {
    type: 'hero';
    titleKey: string;
    taglineKey?: string;
    cta?: CtaSpec;
    ctaSecondary?: CtaSpec;
};

export type CardsCatalogItem = {
    iconText?: string;
    titleKey: string;
    badgeKey?: string;
    descKey?: string;
    action?: (CtaSpec & { variant?: 'glass' | 'primary' });
};

export type CardsSection = {
    type: 'cards';
    variant: 'catalog';
    items: CardsCatalogItem[];
};

export type ComparisonSection = {
    type: 'comparison';
    titleKey: string;
    subtitleKey?: string;
    left: { titleKey: string; itemsKeys: string[] };
    right: { titleKey: string; itemsKeys: string[] };
};

export type CtaSection = {
    type: 'cta';
    titleKey: string;
    bodyKey?: string;
    primary?: CtaSpec;
    secondary?: CtaSpec;
};

export type FormFieldSpec = {
    name: string;
    type: 'text' | 'email' | 'select' | 'textarea' | 'checkbox';
    labelKey: string;
    placeholderKey?: string;
    required?: boolean;
    optionsKey?: string;
    rows?: number;
    width?: 'half' | 'full';
};

export type FormSection = {
    type: 'form';
    variant?: 'demo';
    titleKey: string;
    leadKey?: string;
    badgesKeys?: string[];
    testimonialTextKey?: string;
    testimonialAuthorKey?: string;
    fields: FormFieldSpec[];
    consentKey?: string;
    submitKey: string;
    legalKey?: string;
};

export type SpacerSection = {
    type: 'spacer';
    size?: 'sm' | 'md' | 'lg';
};

export type ManifestoSection = {
    type: 'manifesto';
};

export type ComponentVariant = {
    name: string;
    spec: Record<string, unknown>;
};

export type ComponentShowcaseItem = {
    id: string;
    name: string;
    variants: ComponentVariant[];
};

export type ShowcaseIntroSection = {
    type: 'showcase-intro';
    titleKey: string;
    descriptionKey: string;
};

export type ComponentShowcaseSection = {
    type: 'component-showcase';
    components: ComponentShowcaseItem[];
};

export type SectionSpec =
    | HeroSection
    | CardsSection
    | ComparisonSection
    | CtaSection
    | FormSection
    | ManifestoSection
    | SpacerSection
    | ShowcaseIntroSection
    | ComponentShowcaseSection;

export type PageSpecV1 = {
    version: '1';
    id: string;
    activeNav?: string;
    titleKey?: string;
    themeId?: string;
    sections: SectionSpec[];
};

export type ManifestPageV1 = {
    id: string;
    route: string;
    titleKey?: string;
    spec: string;
    nav?: { labelKey: string; order: number };
};

export type PagesManifestV1 = {
    version: '1';
    defaultLanguage?: string;
    pages: ManifestPageV1[];
};
