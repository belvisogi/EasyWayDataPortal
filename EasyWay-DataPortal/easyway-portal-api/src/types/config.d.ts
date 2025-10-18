// easyway-portal-api/src/types/config.d.ts

export interface BrandingConfig {
  primary_color: string;
  secondary_color: string;
  background_image: string;
  logo: string;
  font: string;
}

export interface LabelsConfig {
  portal_title: string;
  login_button: string;
  welcome_message: string;
}

export interface PathsConfig {
  official_data: string;
  staging_data: string;
  portal_assets: string;
}

export interface TenantConfig {
  branding: BrandingConfig;
  labels: LabelsConfig;
  paths: PathsConfig;
}
