import { DefaultAzureCredential } from "@azure/identity";
import { SecretClient } from "@azure/keyvault-secrets";
import dotenv from "dotenv";
import path from "path";

export async function initSecrets(): Promise<void> {
    // 1. Load local .env files (dev priority)
    dotenv.config();
    dotenv.config({ path: path.resolve(__dirname, "../../.env.local"), override: false });

    // 2. If Azure Key Vault is configured, override/enrich process.env
    const kvName = process.env.KEY_VAULT_NAME;
    if (kvName) {
        try {
            console.log(`[Secrets] Connecting to Azure Key Vault: ${kvName}`);
            const credential = new DefaultAzureCredential();
            const url = `https://${kvName}.vault.azure.net`;
            const client = new SecretClient(url, credential);

            // List all secrets (or specific ones) and load them into process.env
            // Note: listing all might be slow. Better to just use them on demand OR specific load.
            // For this pattern (Env Injection), we usually iterate known keys or load all.
            // To keep cost low ($0.03/10k), listing is ONE op per page (25).

            for await (const secretProperties of client.listPropertiesOfSecrets()) {
                const name = secretProperties.name;
                // AKV names are hyphenated, Env vars are usually UNDERSCORE.
                // Convention: map "MY-SECRET" -> "MY_SECRET" or "MY-SECRET" directly.
                // If we want to override env vars, we might need a mapping strategy.
                // Simple strategy: Load ALL secrets into process.env using their AKV name (and maybe normalized name).

                if (secretProperties.enabled) {
                    const secret = await client.getSecret(name);
                    if (secret.value) {
                        process.env[name] = secret.value;
                        // Optional: Normalize 'DB-CONN-STRING' -> 'DB_CONN_STRING'
                        const normalized = name.replace(/-/g, "_");
                        if (normalized !== name) {
                            process.env[normalized] = secret.value;
                        }
                    }
                }
            }
            console.log("[Secrets] Successfully loaded secrets from Azure Key Vault");
        } catch (error: any) {
            console.warn(`[Secrets] Failed to load from Key Vault '${kvName}':`, error.message);
            // Don't crash in dev if network fails, but maybe crash in prod?
            if (process.env.NODE_ENV === "production") throw error;
        }
    } else {
        // console.log("[Secrets] No KEY_VAULT_NAME set, skipping AKV load.");
    }
}
