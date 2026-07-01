<script>
    import { mail, chevronForwardCircle } from 'ionicons/icons';
	import { webmailLoggedIn as autheticationFlag} from '$components/webmailLogin/userCredsFlagStore';
    import { t } from "$lib/i18n";
	import CredentialLoginModal from './CredentialLoginModal.svelte';
	import Config from "$src/app.config";

	let isOpen = false;
</script>

{#if $autheticationFlag == false && (Config.isAndroid || Config.isDevelopment)}
    <ion-item button on:click={() => (isOpen = true)} aria-hidden>
        <ion-icon size="small" icon={mail} />
        <ion-label class="ion-padding-start">{$t("settings.webmail")}</ion-label>
        <ion-icon size="small" icon={chevronForwardCircle} />
    </ion-item>
{/if}

<CredentialLoginModal bind:isOpen />

<style>
	ion-icon {
		color: var(--app-color-icons);
	}
</style>
