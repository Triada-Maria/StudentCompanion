import { Capacitor } from "@capacitor/core";
import { Preferences } from "@capacitor/preferences";

/**
 * Store webmail credentials for iOS background fetch tasks
 * iOS background tasks cannot access Svelte stores, so we need to persist credentials
 */
export async function storeWebmailCredentialsForBackground(
    username: string,
    password: string
): Promise<void> {
    if (Capacitor.getPlatform() !== "ios") {
        return; // Only needed for iOS
    }

    try {
        await Preferences.set({
            key: "webmail_username",
            value: username,
        });
        await Preferences.set({
            key: "webmail_password",
            value: password,
        });
        console.log("Webmail credentials stored for iOS background fetch");
    } catch (error) {
        console.error("Failed to store webmail credentials:", error);
    }
}

/**
 * Clear stored webmail credentials (call this on logout)
 */
export async function clearWebmailCredentials(): Promise<void> {
    if (Capacitor.getPlatform() !== "ios") {
        return;
    }

    try {
        await Preferences.remove({ key: "webmail_username" });
        await Preferences.remove({ key: "webmail_password" });
        console.log("Webmail credentials cleared");
    } catch (error) {
        console.error("Failed to clear webmail credentials:", error);
    }
}

/**
 * Store Universis access token for iOS background fetch tasks
 * iOS background tasks cannot access Svelte stores, so we need to persist the token
 */
export async function storeUniversisTokenForBackground(
    accessToken: string
): Promise<void> {
    if (Capacitor.getPlatform() !== "ios") {
        return; // Only needed for iOS
    }

    try {
        await Preferences.set({
            key: "login_access_token",
            value: accessToken,
        });
        console.log("Universis access token stored for iOS background fetch");
    } catch (error) {
        console.error("Failed to store access token:", error);
    }
}

/**
 * Clear stored Universis access token (call this on logout)
 */
export async function clearUniversisToken(): Promise<void> {
    if (Capacitor.getPlatform() !== "ios") {
        return;
    }

    try {
        await Preferences.remove({ key: "login_access_token" });
        console.log("Universis access token cleared");
    } catch (error) {
        console.error("Failed to clear access token:", error);
    }
}

/**
 * Schedule iOS background fetch (call this when app becomes active)
 */
export async function scheduleIOSBackgroundFetch(): Promise<void> {
    if (Capacitor.getPlatform() !== "ios") {
        return;
    }

    try {
        const BackgroundTaskHandler = (window as any).BackgroundTaskHandler;
        if (BackgroundTaskHandler?.shared) {
            BackgroundTaskHandler.shared.scheduleBackgroundFetch();
            console.log("iOS background fetch scheduled");
        }
    } catch (error) {
        console.error("Failed to schedule iOS background fetch:", error);
    }
}
