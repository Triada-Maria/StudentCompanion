<script lang="ts">
    import SwipeCard from "./swipeCard.svelte";
    import RecentGrade from "./recentGrades.svelte";
    import Notification from "$components/notifications/notification.svelte";
    import { dismissedItems } from "./dismissedItems";
    import { refresh } from "ionicons/icons";
    import { flip } from "svelte/animate";
    import { quintOut } from 'svelte/easing';
    import { t } from "$lib/i18n";

    export let recentItems: any[] = [];
    export let maxCards = 6;
    let recentlyDismissedItem: any;
    let allRecentItems: any[] = [];
    let showUndoButton = false;
    let timer: any;
    filterRecentItems();

    // ── Date helpers ───────────────────────────────────────────────────

    function getItemDate(item: any): Date {
        if (item.type === 'recentGrade')  return new Date(item.content.gradeModified);
        if (item.type === 'notification') return new Date(item.content.dateReceived);
        return new Date(0);
    }

    function getPeriodKey(item: any): string {
        const now      = new Date();
        const date     = getItemDate(item);
        const today    = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const yesterday = new Date(today.getTime() - 86_400_000);
        const weekAgo  = new Date(today.getTime() - 6 * 86_400_000);
        const itemDay  = new Date(date.getFullYear(), date.getMonth(), date.getDate());

        if (itemDay.getTime() === today.getTime())     return 'today';
        if (itemDay.getTime() === yesterday.getTime()) return 'yesterday';
        if (itemDay >= weekAgo)                        return 'this_week';
        return 'earlier';
    }

    const PERIOD_ORDER = ['today', 'yesterday', 'this_week', 'earlier'] as const;

    // Reactive grouping — updates whenever recentItems changes
    $: groupedItems = (() => {
        const map: Record<string, any[]> = {};
        for (const item of recentItems) {
            const key = getPeriodKey(item);
            (map[key] ??= []).push(item);
        }
        return PERIOD_ORDER
            .filter(p => map[p]?.length)
            .map(p => ({ period: p, items: map[p] }));
    })();


    function addToDismissedItems(id: number) {
        dismissedItems.update(ids => [...ids, id]);
        recentlyDismissedItem = id;
    }

    function removeFromDismissedItems(_id: number) {
        dismissedItems.update(() => []);
    }

    const deleteCard = (id: { detail: number }) => {
        const examId = id.detail;
        recentItems = recentItems.filter(item => item.id !== examId);
        addToDismissedItems(examId);
        showUndoButton = true;
    };

    function restoreDeletedCard() {
        removeFromDismissedItems(recentlyDismissedItem);
        for (const recentItem of allRecentItems) {
            if (recentlyDismissedItem === recentItem.id) {
                recentItems = [...recentItems, recentItem];
                let temp: any[] = [];
                for (const item of allRecentItems) {
                    if (recentItems.includes(item)) temp.push(item);
                }
                recentItems = [...temp];
                hideUndoButton();
                return;
            }
        }
    }

    function hideUndoButton() {
        showUndoButton = false;
        clearTimeout(timer);
    }

    function handleInteraction(event: any) {
        if (event.target.closest('.undoButton')) return;
        hideUndoButton();
        removeEventListeners();
    }

    function addEventListeners() {
        document.addEventListener('touchstart', handleInteraction);
        document.addEventListener('touchmove',  handleInteraction);
        document.addEventListener('focus',      handleInteraction, true);
    }

    function removeEventListeners() {
        document.removeEventListener('touchstart', handleInteraction);
        document.removeEventListener('touchmove',  handleInteraction);
        document.removeEventListener('focus',      handleInteraction, true);
    }

    $: if (showUndoButton) {
        addEventListeners();
        timer = setTimeout(hideUndoButton, 8000);
    } else {
        removeEventListeners();
        clearTimeout(timer);
    }

    function filterRecentItems() {
        allRecentItems = [...recentItems];

        for (const recentItem of recentItems) {
            if ($dismissedItems.includes(recentItem.id)) {
                recentItems = recentItems.filter(item => item.id !== recentItem.id);
            }
        }

        recentItems = recentItems.sort((a, b) =>
            getItemDate(b).getTime() - getItemDate(a).getTime()
        );

        if (recentItems.length > maxCards) {
            recentItems = recentItems.slice(0, maxCards);
        }
    }
</script>

<div class="recentGrades ion-padding">

    {#if recentItems.length === 0}
        <p class="empty-msg">{$t('recentgrades.nonews')}</p>
    {:else}
        <div class="timeline">
            {#each groupedItems as group, gi}

                <!-- Period label row with dot -->
                <div class="tl-row period-row">
                    <div class="tl-left" class:first={gi === 0}>
                        <div class="tl-dot"></div>
                    </div>
                    <span class="tl-period">
                        {$t(`recentgrades.period.${group.period}`).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase()}
                    </span>
                </div>

                <!-- Card rows for this period -->
                {#each group.items as item, ii (item.id)}
                    {@const isLast = gi === groupedItems.length - 1 && ii === group.items.length - 1}
                    <div class="tl-row" animate:flip={{ duration: 500, easing: quintOut }}>
                        <div class="tl-left" class:last={isLast}></div>
                        <div class="tl-card">
                            <SwipeCard id={item.id} on:delete-card={deleteCard}>
                                {#if item.type === "recentGrade"}
                                    <RecentGrade subject={item.content} />
                                {:else}
                                    <Notification notification={item.content} />
                                {/if}
                            </SwipeCard>
                        </div>
                    </div>
                {/each}

            {/each}
        </div>
    {/if}

    <div class="button-container">
        {#if showUndoButton}
            <ion-button class="undoButton" on:click={restoreDeletedCard} aria-hidden>
                <ion-icon icon={refresh}></ion-icon>
            </ion-button>
        {/if}
    </div>

</div>

<style>
    .recentGrades {
        padding: 0;
    }

    .empty-msg {
        padding: 1rem;
        color: var(--ion-color-medium);
    }

    /* ── Timeline layout ─────────────────────────────────────────── */

    .timeline {
        display: flex;
        flex-direction: column;
    }

    .tl-row {
        display: flex;
        align-items: flex-start;
    }

    /*
     * Left column: fixed-width track that holds the dot and/or line.
     * align-self: stretch makes it fill the full row height so ::before
     * can draw a continuous vertical line from top to bottom of each row.
     */
    .tl-left {
        width: 28px;
        flex-shrink: 0;
        position: relative;
        align-self: stretch;
        display: flex;
        justify-content: center;
    }

    /* The continuous vertical line */
    .tl-left::before {
        content: '';
        position: absolute;
        left: 50%;
        top: 0;
        bottom: 0;
        width: 2px;
        background: var(--ion-color-medium);
        opacity: 0.35;
        transform: translateX(-50%);
    }

    /*
     * First dot: hide the line above the dot so it doesn't
     * extend into empty space at the top.
     */
    .tl-left.first::before {
        top: 18px; /* dot margin-top (6px) + dot diameter (10px) + 2px */
    }

    /* Last card: taper the line so it ends at the card midpoint */
    .tl-left.last::before {
        bottom: 50%;
    }

    /* Period dot — sits on top of the line via z-index */
    .tl-dot {
        width: 10px;
        height: 10px;
        border-radius: 50%;
        background: var(--ion-color-primary);
        margin-top: 6px;
        flex-shrink: 0;
        position: relative;
        z-index: 1;
    }

    /* Period label */
    .tl-period {
        padding-left: 8px;
        padding-top: 3px;
        padding-bottom: 6px;
        font-size: 0.68rem;
        font-weight: 700;
        letter-spacing: 0.07em;
        color: var(--ion-color-medium);
    }

    /* Card area — fills remaining width, with bottom gap between cards */
    .tl-card {
        flex: 1;
        min-width: 0;
        padding-left: 8px;
        padding-bottom: 0.5rem;
    }

    /* ── Undo button ─────────────────────────────────────────────── */

    .button-container {
        position: fixed;
        bottom: 1rem;
        right: 1rem;
        z-index: 999;
    }

    .undoButton {
        --border-radius: 1rem;
        --box-shadow: var(--shadow-short-md);
    }
</style>