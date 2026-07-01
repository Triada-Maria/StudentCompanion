import { toastController } from 'ionic-svelte';
import type { ToastOptions } from '@ionic/core';
import { webmailLoggedIn } from '$components/webmailLogin/userCredsFlagStore';
import { userCreds } from '$stores/credentials.store';
import { webmailCheckCredentials } from '$lib/-webmail/dataService/core';

export async function showToast(toast: ToastOptions) {
    const toast_ = await toastController.create(toast);
    toast_.present();
}

export async function checkCredsValidity(username: string, password: string) {
    if (!username || !password) return false;

    if (username.includes("@"))
        username = username.substring(0, username.indexOf("@"))

    if (await webmailCheckCredentials(username, password)){
        webmailLoggedIn.set(true);
        userCreds.set({ username: username, password: password });
        return true;
    }
    return false;
}
