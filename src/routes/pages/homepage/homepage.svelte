<script lang="ts">
	import { averages } from '$lib/functions/gradeAverages/averages';
	import { neoUniversisGet } from '$lib/dataService';
	import man from '$lib/assets/man.svg';
	import { locationOutline, walletOutline, shield, settingsOutline, calendarOutline, shieldOutline, linkOutline, notificationsCircle, cloudOfflineOutline, barbellOutline, addOutline } from 'ionicons/icons';
	import woman from '$lib/assets/woman.svg';
	import avatar from '$lib/assets/.svg';
	import { register } from 'swiper/element/bundle';
	import { navController } from '$components/shared/StackedNav';
	import PersonalInfo from '$src/routes/personalInfo/personalInfo.svelte';
	import RecentItems from '$components/recentResults/recents.svelte';
	import HomepageSkeleton from '$lib/components/homepage/homepageSkeleton.svelte';
	import { goto } from '$app/navigation';
	import { getVocativeCase } from '$lib/globalFunctions/getVocativeCase';
	import ErrorLandingCard from '$components/errorLanding/ErrorLandingCard.svelte';
	import { getLocale, t } from '$lib/i18n';
	import WalletCard from '$lib/components/wallet/WalletCard.svelte';
	import { EventStore } from '$lib/components/calendar/event/EventStore';
	import type { Event } from '$lib/components/calendar/event/Event';
	import { buildCalendarWeeks, type DayObject } from '$lib/components/calendar/calendarUtils';
	import Links from '$src/routes/quickLinks/quickLinks.svelte';
	import Notifications from '$src/routes/notifications/notificationsPage.svelte';
	import { fetchUniversisEvents } from '$lib/components/calendar/calendarUtils';
	import { registerPlugin, Capacitor } from '@capacitor/core';
	import { Browser } from '@capacitor/browser';
	import { locale } from '$lib/i18n';
	import { StatusBar, Style } from '@capacitor/status-bar';
	import AdBanner from './ad_banner.svelte';
	import { slide } from 'svelte/transition';
	import { cubicOut } from 'svelte/easing';
	import authlogo from '$lib/assets/auth_white.png';

	// Register the custom AppLauncher plugin
	const AppLauncherPlugin = registerPlugin('AppLauncherPlugin');

	register();
	// Get upcoming events (next 2 events)
	$: upcomingEvents = $EventStore
		.filter((event: Event) => new Date(event.slot.start) >= new Date())
		.sort((a: Event, b: Event) => new Date(a.slot.start).getTime() - new Date(b.slot.start).getTime())
		.slice(0, 2);

	// Mini calendar state
	let currentDate = new Date();
	let miniMonth = currentDate.getMonth();
	let miniYear = currentDate.getFullYear();
	let miniWeeks: DayObject[][] = [];

	$: {
		miniWeeks = buildCalendarWeeks(miniMonth, miniYear, $EventStore);
	}

	function formatEventDate(date: Date): string {
		const eventDate = new Date(date);
		const today = new Date();
		const tomorrow = new Date(today);
		tomorrow.setDate(tomorrow.getDate() + 1);

		if (eventDate.toDateString() === today.toDateString()) {
			return $t('homepage.today');
		} else if (eventDate.toDateString() === tomorrow.toDateString()) {
			return $t('homepage.tomorrow');
		} else {
			return eventDate.toLocaleDateString(getLocale(), { month: 'short', day: 'numeric' });
		}
	}

	async function openCapacitorSite() {
		await Browser.open({ url: 'https://gym.auth.gr/reservations/' });
	};

	function formatEventTime(date: Date): string {
		return new Date(date).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
	}

	let givenName = '';
	let gender = '';
	let numPassedSubjects = 0;
	let numSubjects = 0;
	let average = 0;
	let departmentName = '';
	let studyLevel = '';
	let actualSemester = 0;
	let studentStatus = '';

	let aem = '';
	let apm = '';
	let inscriptionYear = '';
	let birthDate = '';
	let email = '';
	let username = '';
	let familyName = '';

	// Toggle state
	let isProfileExpanded = false;

	let isFlipped = false;

	async function handleCampusSafetyClick() {
		const packageName = 'gr.auth.android.incidentmanager';
		const playStoreUrl = `https://play.google.com/store/apps/details?id=${packageName}&hl=el`;

		const isAndroid = Capacitor.getPlatform() === 'android';

		if (isAndroid) {
			try {
				// Try to launch the app directly using our custom plugin
				const result = await AppLauncherPlugin.launchApp({ packageName });
				
				if (!result.launched) {
					// App not installed, open Play Store
					window.location.href = `market://details?id=${packageName}`;
				}
			} catch (err) {
				console.error('Error launching app:', err);
				window.location.href = `market://details?id=${packageName}`;
			}
		} else {
			// For other platforms, go to Play Store
			window.location.href = playStoreUrl;
		}
	}

	async function getInfo(locale: string) {
		if($EventStore.length === 0) 
			fetchUniversisEvents();
		
		let expandedLocale = locale == 'el' ? '' : '($expand=locale)';

		let personalData = await neoUniversisGet(
			'Students/me?$expand=studyProgram($expand=studyLevel'+expandedLocale+'), department'+expandedLocale + (expandedLocale !== '' ? ', person' +expandedLocale : '')
		);


		givenName = expandedLocale === '' ? personalData.person.givenName : personalData.person.locale.givenName;
		gender = personalData.person.gender;
		departmentName = expandedLocale === '' ? personalData.department?.name || 'Αδυναμία φόρτωσης' : personalData.department?.locale.name || 'Αδυναμία φόρτωσης';
		studyLevel = expandedLocale === '' ? personalData.studyProgram?.studyLevel?.name : personalData.studyProgram?.studyLevel?.locale.name || 'Αδυναμία φόρτωσης' ;
		actualSemester = personalData.actualSemester || null;
		studentStatus = personalData.studentStatus.id == 1 ? $t('homepage.studentStatusActive') : $t('homepage.studentStatusInactive');
		aem = personalData.studentIdentifier;
		apm = personalData.uniqueIdentifier;
		inscriptionYear = personalData.inscriptionYear?.name ?? '';
		birthDate = personalData.person.birthDate?.slice(0, 10) ?? '';
		email = personalData.person.email;
		familyName = expandedLocale === '' 
			? personalData.person.familyName 
			: personalData.person.locale?.familyName ?? personalData.person.familyName;
		username = personalData.person.email.split('@')[0];

		let subjects = (await neoUniversisGet('students/me/courses?$top=-1')).value;

		let passedSubjects = subjects.filter(
			(course: { isPassed: number }) => course.isPassed == 1
		);

		numSubjects = subjects?.length;
		numPassedSubjects = passedSubjects?.length;

		averages().then((result) => {
			average = (result as { weighted_avg: number }).weighted_avg;
		});
	}

	let isStatusBarHidden = false;
	const SCROLL_THRESHOLD = 12;
	
	async function handleScroll(event: CustomEvent) {
		const scrollTop = event.detail.scrollTop;

		if (scrollTop > SCROLL_THRESHOLD && !isStatusBarHidden) {
			await StatusBar.hide();
			isStatusBarHidden = true;
		} else if (scrollTop <= SCROLL_THRESHOLD && isStatusBarHidden) {
			await StatusBar.show();
			isStatusBarHidden = false;
		}
	}

	$: StatusBar.setStyle({ style: Style.Dark });

</script>

<ion-page>

	<ion-content id="homepage_content" fullscreen={false} on:ionScroll={handleScroll}>
		{#await getInfo($locale)}
		<HomepageSkeleton />
		{:then}
		<div id="scrolled_content">
			<div class="personal-section {isProfileExpanded ? 'expanded-personal-section' : ''}">
				<div class="info-container">
					<div class="header ion-activatable" on:click={() => { isProfileExpanded = !isProfileExpanded;}} aria-hidden>
						<ion-ripple-effect/>
						<div class="welcome">
							{#if gender === 'Α'}
							<img class="avatar" alt="man" src={man} />
							{:else}
							<img class="avatar" alt="woman" src={woman} />
							{/if}
							<div>
								<h6 style="color: var(--ion-color-dark-tint) !important; padding-left: 0.2rem;">{$t('homepage.greeting')}, <span><b>{getVocativeCase(givenName)}!</b></span></h6>
							</div>
						</div>
					</div>
					<div class="settings-icon-container ion-activatable" on:click={() => {navController.push(PersonalInfo);}} aria-hidden>
						<ion-ripple-effect/>
						<ion-icon icon={settingsOutline} class="settings-icon"></ion-icon>
					</div>

				</div>

				{#if isProfileExpanded}
					<div class="profile-panel" transition:slide={{ duration: 280, easing: cubicOut }}>
						<div class="profile-panel-inner">
							<div class="profile-info-grid">
								<div class="profile-info-item">
									<span class="profile-info-label">{$t('homepage.fullname')}</span>
									<span class="profile-info-value">{givenName} {familyName}</span>
								</div>
								<div class="profile-info-item">
									<span class="profile-info-label">{$t('homepage.enrollmentYear')}</span>
									<span class="profile-info-value">{inscriptionYear}</span>
								</div>
								<div class="profile-info-item">
									<span class="profile-info-label">{$t('homepage.aem')}</span>
									<span class="profile-info-value">{aem}</span>
								</div>
								<div class="profile-info-item">
									<span class="profile-info-label">{$t('homepage.apm')}</span>
									<span class="profile-info-value">{apm}</span>
								</div>
								<div class="profile-info-item">
									<span class="profile-info-label">{$t("homepage.email")}</span>
									<span class="profile-info-value">{email}</span>
								</div>
								<div class="profile-info-item">
									<span class="profile-info-label">{$t("homepage.username")}</span>
									<span class="profile-info-value">{username}</span>
								</div>
							</div>
						</div>
					</div>
				{/if}

			</div>

			
			
			<div class="services-section" style="padding-block: 0.5rem !important;">
				<div class="service-buttons-grid">
					<div class="service-button ion-activatable" on:click={() => {navController.push(Links);}} aria-hidden>
						<ion-icon icon={linkOutline} color="primary" class="service-button-icon"></ion-icon>
						<ion-ripple-effect></ion-ripple-effect>
					</div>
					<div class="service-button ion-activatable" on:click={handleCampusSafetyClick} aria-hidden>
						<ion-icon icon={shield} color="danger" class="service-button-icon"></ion-icon>
						<ion-ripple-effect></ion-ripple-effect>
					</div>
					<div class="service-button ion-activatable" on:click={openCapacitorSite} aria-hidden>
						<ion-icon icon={barbellOutline} color="success" class="service-button-icon"></ion-icon>
						<ion-ripple-effect></ion-ripple-effect>
					</div>
				</div>
			</div>

			<div class="wallet-section" style="padding: 0 1.5rem 1.5rem 1.5rem;">
				<WalletCard 
				{departmentName}
				{studyLevel}
				{actualSemester}
				{numPassedSubjects}
				{numSubjects}
				{average}
				/>
			</div>
			
			<div class="events-section" style="padding-inline:0 !important;">
				<!-- Upcoming Events Section -->
				{#if upcomingEvents.length > 0}
					<div class="section-title-row" style="padding-left: 1.5rem;">
						<h4 class="middle-title">{$t('homepage.dontForget')}</h4>
						<svg class="zigzag-line" viewBox="0 0 100 10" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg">
							<polyline
								points="0,8 5,2 10,8 15,2 20,8 25,2 30,8 35,2 40,8 45,2 50,8 55,2 60,8 65,2 70,8 75,2 80,8 85,2 90,8 95,2 100,8"
								fill="none"
								stroke="currentColor"
								stroke-width="1.8"
								stroke-dasharray="5 3"
								stroke-linecap="round"
								opacity="0.28"
							/>
						</svg>
					</div>				
				<div class="events-container" style="padding-inline:0 !important;">
					{#each upcomingEvents as event}
						<div class="event-card ion-activatable" data-type={event.type} aria-hidden
							on:click={() => { goto(`/pages/calendar?showEventId=${encodeURIComponent(event.id)}&eventDate=${encodeURIComponent((new Date(event.slot.start)).toISOString())}`); }}>
							<div class="event-header">
							<div class="event-type-badge">
								{event.type}
							</div>
							<span class="event-time-top">
								{formatEventDate(event.slot.start)} • {formatEventTime(event.slot.start)}
							</span>
							</div>
							<h5 class="event-title">{event.title}</h5>
							<div class="event-footer">
							{#if event.location}
								<div class="event-detail-item">
								<ion-icon icon={locationOutline} class="event-footer-icon"></ion-icon>
								<span class="event-footer-text">{event.location}</span>
								</div>
							{/if}
							</div>
							<ion-ripple-effect></ion-ripple-effect>
						</div>
					{/each}
				</div>
			{:else}
			<!-- Create Event Prompt -->
			<h4 class="middle-title">{$t('homepage.dontForget')}</h4>
			<!-- svelte-ignore a11y-click-events-have-key-events -->
			<!-- svelte-ignore a11y-no-static-element-interactions -->
			<div class="events-container">
				<!-- svelte-ignore a11y-click-events-have-key-events -->
				<!-- TODO: Convert to ion card! -->
				<div class="event-card create-event-card" on:click={() => goto('/pages/calendar')}>
					<h5 class="event-title" style="opacity: 0.7;">{$t('homepage.noEvents')}</h5>
					<div class="event-header">
						<div class="event-header-left">
							<div class="event-type-badge">
								<ion-icon icon={addOutline}></ion-icon>
							</div>
							<div class="event-detail-item">
								<span class="event-time">
									{$t('homepage.createNew')}
								</span>
							</div>
						</div>
					</div>
				</div>
			</div>
			{/if}

		</div>
		<AdBanner departmentName={departmentName} semester={actualSemester}/>
		<div class="updates-section">
			<div style="display: flex; justify-content: space-between; align-items: center;">
				<h4 class="middle-title" style="margin-bottom: 0;">{$t('homepage.updates')}</h4>
				<!-- svelte-ignore a11y-click-events-have-key-events -->
				<!-- svelte-ignore a11y-no-static-element-interactions -->
				<div class="service-icon-container" on:click={() => {navController.push(Notifications);}}>
					<ion-label style="font-size: 0.85rem; font-weight: 500; color: var(--ion-color-medium);">{$t("homepage.seemore")}</ion-label>
					<!-- <ion-icon icon={notificationsCircle} style="font-size:2rem;"></ion-icon> -->
				</div>
			</div>
			<div style="margin-top: 0.5rem;">
				<RecentItems maxCards={6}/>
			</div>
		</div>
	</div>
	
	{:catch error}
	<ErrorLandingCard errorMsg={error} />
	{/await}
</ion-content>
</ion-page>

<style>
	:global(ion-tabs):has(#homepage_content) :global(ion-toolbar){
		padding-top: var(--ion-safe-area-top) !important;
	}
	
	:global(ion-tabs):has(#homepage_content){
		padding-top: 0px !important;
	}


	.personal-section {
		position: relative;
		padding: 0.5rem 1.5rem 0.5rem 1.5rem;
		/* background: radial-gradient( 
			ellipse at 72% -5%,
			#6d5ef2 0%,
			#4C3FD6 18%,
			#1D2A9C 42%,
			#0D1870 65%
		); */
		border-radius: 0 0 1.5rem 1.5rem;
	}

	
	:global(body.dark) .expanded-personal-section {
		padding-bottom: 1rem;
		background: var(--app-color-primary) !important;
		border-radius: 0 0 1.5rem 1.5rem;
	}

	.expanded-personal-section {
		padding-bottom: 1rem;
		background: white;
		border-radius: 0 0 1.5rem 1.5rem;
	}

/* 
	background: radial-gradient( 
			ellipse at 72% -5%,
			#6c3030 0%,
			#5d1d1d 18%,
			#430f0f 42%,
			#2c0707 65%
		); */

	/* 		background: radial-gradient( 
			ellipse at 72% -5%,
			#6d5ef2 0%,
			#4C3FD6 18%,
			#1D2A9C 42%,
			#0D1870 65%
		);
	} */
	.avatar {
		width: 3rem;
		margin-block-start: 0rem;
		margin-inline-end: 0.5rem;
	}

	.info-container {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 1rem;
		/* padding-bottom: 2rem; */
		position: relative;
			}

	.header {
		display: flex;
		align-items: center;
		flex: 1;
		overflow: hidden;
		border-radius: 50px;
		position: relative;
	}

	.welcome {
		display: flex;
		align-items: center;
	}


	.settings-icon-container {
		display: flex;
		align-items: center;
		cursor: pointer;
		position: relative;
		border-radius: 150px;
		overflow: hidden;
		padding: 4px;
	}

	.service-icon-container {
		display: flex;
		align-items: center;
		cursor: pointer;
	}


	.service-buttons-grid {
		display: grid;
		grid-template-columns: 1fr 1fr 1fr;
		gap: 1rem;
		position: relative;
	}

	.service-button {
		display: flex;
		flex-direction: row;
		align-items: center;
		justify-content: center;
		gap: 1rem;
		padding: 0.5rem 1rem;
		border-radius: 3rem;
		cursor: pointer;
		transition: all 0.2s ease;
		background: var(--app-color-map-input);
		border: 1px solid var(--ion-color-light-shade);
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
		position: relative;
		overflow: hidden;
		backdrop-filter: blur(12px);
		-webkit-backdrop-filter: blur(12px); /* Safari */
		/* border: 1px solid rgba(255, 255, 255, 0.25); */
		/* border-top: 1px solid rgba(255, 255, 255, 0.45); light hits top edge */
		box-shadow:
			0 4px 16px rgba(0, 0, 0, 0.12),
			inset 0 1px 0 rgba(255, 255, 255, 0.2); /* inner top highlight */
	}

	.service-button:active {
    background: rgba(255, 255, 255, 0.2);
    box-shadow:
        0 2px 8px rgba(0, 0, 0, 0.1),
        inset 0 1px 0 rgba(255, 255, 255, 0.3);
    transform: scale(0.97);
}

	.service-button-icon {
		font-size: 1.5rem;
		pointer-events: none;
	}

	.settings-icon {
		font-size: 1.5rem;
		color: var(--ion-color-medium);
	}

	.events-section, .updates-section, .services-section {
		padding: 0rem 1.5rem 1.5rem 1.5rem;
	}

	.services-section {
		/* padding-top: 2.5rem !important; */
		transition: margin-top 0.6s ease;
	}

	.middle-title {
		margin: 0 0 0.625rem 0;
		font-size: 1.125rem;
		font-weight: 600;
		color: var(--ion-color-dark-tint);
	}

	.events-container {
  display: flex;
  flex-direction: row;
  gap: 0.75rem;
  overflow-x: auto;
  padding-bottom: 0.5rem;
  scrollbar-width: none;
  -ms-overflow-style: none;
  /* remove the old dashed border */
}

.events-container::-webkit-scrollbar {
  display: none;
}

.events-container> div:first-child {
    margin-left: 1.5rem;
    padding-left: 1.5rem;
}


.event-card {
  position: relative;
  min-width: 185px;
  flex-shrink: 0;
  border-radius: 1rem;
  padding: 0.875rem;
  cursor: pointer;
  overflow: hidden;
  border: none;
  color: white;
}

/* Card background colors per type */
.event-card[data-type="TEST"] {
  background: #e53935;
}
.event-card[data-type="ASSIGNMENT"] {
  background: #fb8c00;
}
.event-card[data-type="CLASS"] {
  background: #43a047;
}
.event-card[data-type="TASK"] {
  background: #1e88e5;
}
.event-card[data-type="OTHER"] {
  background: #bcbaba;
}

.event-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.6rem;
  gap: 0.5rem;
}

.event-type-badge {
  font-size: 0.65rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  padding: 0.2rem 0.5rem;
  border-radius: 0.3rem;
  background: rgba(255, 255, 255, 0.25);
  color: white;
  flex-shrink: 0;
}

.event-time-top {
  font-size: 0.7rem;
  color: rgba(255, 255, 255, 0.85);
  font-weight: 500;
  text-align: right;
}

.event-title {
  margin: 0 0 0.625rem 0;
  font-size: 1rem;
  font-weight: 700;
  color: white;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: normal;
  display: -webkit-box;
white-space: nowrap; /* Don't forget this one */
  -webkit-box-orient: vertical;
}

.event-footer {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  margin-top: 0.5rem;
  padding-top: 0.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.25);
}

.event-detail-item {
  display: flex;
  align-items: center;
  gap: 0.35rem;
  
}

.event-footer-icon {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.8);
  flex-shrink: 0;
}

.event-footer-text {
  font-size: 0.78rem;
  color: rgba(255, 255, 255, 0.9);
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

	
	/* Profile panel sits inside the gradient section */
	.profile-panel {
		margin-bottom: 0.5rem;
		margin-top: 0.5rem;
		overflow: hidden;
	}

	.profile-panel-inner {
		/* background: rgba(255, 255, 255, 0.1); */
		backdrop-filter: blur(12px);
		-webkit-backdrop-filter: blur(12px);
		/* border: 1px solid rgba(255, 255, 255, 0.18); */
		border-radius: 1rem;
		/* padding: 1rem; */
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.profile-info-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 0.6rem;
	}

	.profile-info-item {
		display: flex;
		flex-direction: column;
		gap: 0.1rem;
		background: rgba(74, 73, 73, 0.08);
		border-radius: 0.6rem;
		padding: 0.5rem 0.65rem;
	}

	.profile-info-label {
		font-size: 0.65rem;
		font-weight: 600;
		letter-spacing: 0.5px;
		color: var(--ion-color-medium);
	}

	.profile-info-value {
		font-size: 0.85rem;
		font-weight: 500;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		white-space: normal;       /* allow wrapping */
    	word-break: break-word;    /* break long strings like emails */
	}

.section-title-row {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    margin-bottom: 0.625rem;
}

.section-title-row .middle-title {
    margin-bottom: 0;
    white-space: nowrap;
    flex-shrink: 0;
}

.zigzag-line {
    flex: 1;
    height: 10px;
    color: var(--ion-color-medium);
}
	
</style>
