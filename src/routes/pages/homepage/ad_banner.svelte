<script lang="ts">
	import { onMount } from "svelte";
    import { neoUniversisGet } from "$src/lib/dataService";
    import adBanner from '$lib/assets/Advert_dark.png';

    export let semester;
    export let departmentName;


    let isPast = new Date() > new Date("2026-02-17T15:00:00.000+02:00");
</script>

<!-- {#if !isPast && departmentName=="ΤΜΗΜΑ ΠΛΗΡΟΦΟΡΙΚΗΣ" && semester <= 8} -->
    <div id="ad_banner">
        <a href="https://docs.google.com/forms/d/e/1FAIpQLSf1lqNlvackYWPg0EprvJHgL6Nqhsbxhvpd7BC1f3sR8cWmbg/viewform?usp=sharing&ouid=104810930590793751390" target="_blank" class="feedback-link" style="background-image: url({adBanner});">
        </a>
    </div>
<!-- {/if} -->
<style>
    #ad_banner {
        border-radius: 1rem;
        overflow: hidden;
        aspect-ratio: 896/225;
        margin-left: 1.5rem;
        margin-right: 1.5rem;
        margin-bottom: 1.5rem;
    }

    #ad_banner a {
        width: 100%;
        height: 100%;
        display: flex;
        align-items: center;
        justify-content: center;
        text-decoration: none;
        background-size: cover;
        background-position: center;
        background-repeat: no-repeat;
    }

    .feedback-container {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 100%;
        height: 100%;
    }

    .feedback-text {
        font-size: 1.5rem;
        font-weight: 600;
        color: var(--ion-text-color);
        margin: 0;
        text-align: center;
    }
</style>