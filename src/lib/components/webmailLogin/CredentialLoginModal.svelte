<script lang="ts">
    import { eye, eyeOff } from 'ionicons/icons';
    import { t } from '$lib/i18n';
    import { checkCredsValidity, showToast } from './credentialLogin';

    export let isOpen = false;

    let username = '';
    let password = '';
    let showPassword = false;

    function reset() {
        username = '';
        password = '';
        showPassword = false;
    }

    function cancel() {
        isOpen = false;
    }

    async function submit() {
        const user = username?.trim();
        const pass = password;

        if (!user || !pass) {
            await showToast({
                color: 'danger',
                duration: 1000,
                message: $t('credential.missing_fields'),
                mode: 'ios',
                translucent: true,
                layout: 'stacked',
            });
            return;
        }

        const valid = await checkCredsValidity(user, pass);
        if (!valid) {
            await showToast({
                color: 'danger',
                duration: 1000,
                message: $t('credential.failed'),
                mode: 'ios',
                translucent: true,
                layout: 'stacked',
            });
            return;
        }

        await showToast({
            color: 'success',
            duration: 1000,
            message: $t('credential.success'),
            mode: 'ios',
            translucent: true,
            layout: 'stacked',
        });
        isOpen = false;
    }

    function handleDismiss() {
        isOpen = false;
        reset();
    }
</script>

<ion-modal is-open={isOpen} on:ionModalDidDismiss={handleDismiss} mode="ios">
    <div class="dialog">
        <h2>{$t('credential.title')}</h2>

        <div class="inputs">
            <ion-input
                class="alert-input"
                mode="ios"
                type="text"
                placeholder={$t('credential.academic_name')}
                value={username}
                autocapitalize="off"
                autocomplete="username"
                on:ionInput={(e) => (username = e.detail.value ?? '')}
            />

            <ion-input
                class="alert-input"
                mode="ios"
                type={showPassword ? 'text' : 'password'}
                placeholder={$t('credential.password')}
                value={password}
                autocomplete="current-password"
                on:ionInput={(e) => (password = e.detail.value ?? '')}
            >
                <ion-button
                    slot="end"
                    fill="clear"
                    class="eye"
                    aria-hidden
                    aria-label={showPassword ? $t('credential.hide_password') : $t('credential.show_password')}
                    on:click={() => (showPassword = !showPassword)}
                >
                    <ion-icon slot="icon-only" icon={showPassword ? eyeOff : eye} />
                </ion-button>
            </ion-input>
        </div>

        <div class="buttons">
            <button type="button" class="alert-button" on:click={cancel}>{$t('credential.cancel')}</button>
            <button type="button" class="alert-button strong" on:click={submit}>{$t('credential.login')}</button>
        </div>
    </div>
</ion-modal>

<style>
    /* Replicate the native iOS alert: narrow centered dialog. */
    ion-modal {
        --width: 270px;
        --max-width: 270px;
        --height: auto;
        --border-radius: 13px;
        --background: var(--ion-overlay-background-color, var(--ion-color-step-100, var(--ion-background-color-step-100, #f9f9f9)));
    }

    .dialog {
        display: flex;
        flex-direction: column;
    }

    h2 {
        margin: 0;
        padding: 16px 16px 4px;
        font-size: 17px;
        font-weight: 600;
        text-align: center;
    }

    .inputs {
        display: flex;
        flex-direction: column;
        gap: 8px;
        padding: 12px 16px 16px;
    }

    .alert-input {
        --background: transparent;
        --padding-start: 8px;
        --padding-end: 8px;
        --padding-top: 6px;
        --padding-bottom: 6px;
        min-height: 34px;
        border: 0.55px solid rgba(128, 128, 128, 0.5);
        border-radius: 6px;
        font-size: 14px;
    }

    /* Keep the visibility toggle compact so it sits neatly inside the field. */
    .eye {
        --padding-start: 4px;
        --padding-end: 4px;
        height: 28px;
        margin: 0;
    }

    .buttons {
        display: flex;
        border-top: 0.55px solid rgba(128, 128, 128, 0.4);
    }

    .alert-button {
        flex: 1 1 0;
        padding: 12px;
        background: transparent;
        border: none;
        font-size: 17px;
        color: var(--ion-color-primary, #3880ff);
        cursor: pointer;
    }

    .alert-button + .alert-button {
        border-left: 0.55px solid rgba(128, 128, 128, 0.4);
    }

    .alert-button.strong {
        font-weight: 600;
    }

    .alert-button:active {
        background: rgba(128, 128, 128, 0.15);
    }
</style>
