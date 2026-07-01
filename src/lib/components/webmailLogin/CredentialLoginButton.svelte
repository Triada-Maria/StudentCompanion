<script lang="ts">
    import { keySharp } from 'ionicons/icons';
	import { webmailLoggedIn as autheticationFlag} from '$components/webmailLogin/userCredsFlagStore';
    import { t } from "$lib/i18n";
	import CredentialLoginModal from "./CredentialLoginModal.svelte";

	let isOpen = false;
</script>

{#if $autheticationFlag == false}
    <ion-chip mode="ios" color="dark" on:click={() => (isOpen = true)} aria-hidden>
        <ion-icon icon={keySharp} color="dark"></ion-icon>
        <ion-label>{$t("settings.webmail")}</ion-label>
    </ion-chip>
{/if}

<CredentialLoginModal bind:isOpen />
