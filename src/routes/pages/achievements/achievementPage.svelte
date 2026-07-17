<script lang="ts">
	import AppCard from "$components/shared/AppCard.svelte";
    import SubPageHeader from "$components/shared/subPageHeader.svelte";
	import { getAchievements } from "$src/lib/globalFunctions/achievementEngine";
    import {trophyOutline} from "ionicons/icons"
</script>

<SubPageHeader title="Achievements" stackedNav/>
<ion-content fullscreen>
    {#each getAchievements() as achievement}
        {#if achievement.achieved}
            <AppCard padding>
                <div class="achievement_contents">
                    <ion-icon icon={trophyOutline} style="font-size: 24px;"/>
                    <ion-card-title>{achievement.title}</ion-card-title>
                </div>
            </AppCard>
        {/if}
    {/each}
</ion-content>

<style>
    .achievement_contents {
        display: flex;
        flex-direction: row;
        gap: 1rem;
    }
</style>