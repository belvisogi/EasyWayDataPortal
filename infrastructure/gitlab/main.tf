terraform {
  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "~> 16.0"
    }
  }
}

provider "gitlab" {
  base_url = var.gitlab_url
  # Token passed via env var GITLAB_TOKEN
}

# --- GROUPS (The Architecture) ---

resource "gitlab_group" "client_root" {
  name        = var.client_name
  path        = lower(var.client_name)
  description = "Root Group for ${var.client_name} Sovereign Cloud"
  visibility_level = "private"
}

resource "gitlab_group" "platform" {
  name             = "Platform"
  path             = "platform"
  parent_id        = gitlab_group.client_root.id
  description      = "Core Agents and Infrastructure"
}

resource "gitlab_group" "business" {
  name             = "Domains"
  path             = "domains"
  parent_id        = gitlab_group.client_root.id
  description      = "Business Domains (Finance, HR, Logistics) - DDD Structure"
}

# --- AGENT USERS (The Staff) ---

# Note: In self-managed, we create users. 
# Ideally, these should be Service Accounts, but Standard Users work universally.

resource "gitlab_user" "bot_guard" {
  name             = "Agent Guard"
  username         = "bot_guard_${lower(var.client_name)}"
  email            = "guard@${lower(var.client_name)}.local"
  password         = var.initial_bot_password
  is_admin         = false
  projects_limit   = 10
  can_create_group = false
  skip_confirmation = true
}

resource "gitlab_user" "bot_release" {
  name             = "Agent Release"
  username         = "bot_release_${lower(var.client_name)}"
  email            = "release@${lower(var.client_name)}.local"
  password         = var.initial_bot_password
  is_admin         = false # Release agent doesn't need admin, just Maintainer role
  skip_confirmation = true
}

# --- MEMBERSHIP (The RBAC via Inheritance) ---

# --- MEMBERSHIP (The Safer Split Model) ---

# 1. DEVELOPERS -> BUSINESS (WRITE)
# I dev umani possono "rompere" solo il codice di business.
resource "gitlab_group_membership" "dev_business" {
  group_id     = gitlab_group.business.id
  user_id      = gitlab_user.bot_developer.id
  access_level = "developer"
}

# 2. DEVELOPERS -> PLATFORM (READ-ONLY)
# I dev possono VEDERE gli agenti (per imparare/debuggare) ma NON toccarli.
resource "gitlab_group_membership" "dev_platform" {
  group_id     = gitlab_group.platform.id
  user_id      = gitlab_user.bot_developer.id
  access_level = "reporter"
}

# 3. MAINTAINERS (Release Agent)
# Lui deve poter mergiare ovunque.
resource "gitlab_group_membership" "release_root" {
  group_id     = gitlab_group.client_root.id
  user_id      = gitlab_user.bot_release.id
  access_level = "maintainer"
}

# 4. GUARD (Reporter Root)
# Il poliziotto deve poter leggere tutto.
# --- LABELS (The Taxonomy) ---
# Definiamo il linguaggio comune (PBI, Bug, Release) a livello Root.
# Tutti i progetti erediteranno queste lables.

resource "gitlab_group_label" "type_feature" {
  group       = gitlab_group.client_root.id
  name        = "type::feature"
  description = "Product Backlog Item (PBI) - Nuova funzionalità"
  color       = "#428BCA" # Blue
}

resource "gitlab_group_label" "type_bug" {
  group       = gitlab_group.client_root.id
  name        = "type::bug"
  description = "Difetto o Errore funzionale"
  color       = "#D9534F" # Red
}

resource "gitlab_group_label" "type_release" {
  group       = gitlab_group.client_root.id
  name        = "type::release"
  description = "Deploy Work Item - Tracking del Rilascio"
  color       = "#5CB85C" # Green
}

resource "gitlab_group_label" "priority_high" {
  group       = gitlab_group.client_root.id
  name        = "priority::high"
  description = "Bloccante o Urgente"
  color       = "#FF0000" # Bright Red
}
