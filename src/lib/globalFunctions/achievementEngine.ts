import CapacitorPersistedStore from "$lib/storage/capacitorPersistedStore";
import { get } from "svelte/store";
import { neoUniversisGet } from "../dataService";
import { toastController } from "ionic-svelte";
import { trophy } from "ionicons/icons";


const starterAchievements = {
    fivePassed: {
        achieved: false,
        title: "Pass 5 courses"
    },
    fiveTens: {
        achieved: true,
        title: "Get 5 perfect grades"
    }
}

export const achievementStore = new CapacitorPersistedStore(starterAchievements, 'achievementStore')

async function fivePassedAchievement(){

    if (get(achievementStore).fivePassed.achieved){
        return;
    }

    const passed = (await neoUniversisGet("students/me/courses?$filter=isPassed eq 1&$count=true"))["@odata.count"]

    
    if (passed > 5) {
        achievementStore.update((newAchievementStore) => {newAchievementStore.fivePassed.achieved = true; return newAchievementStore})
    }

    const toast = await toastController.create({
           color: 'success',
           duration: 4000,
           message: 'Πέρασες 5 μαθήματα!.',
           position: 'top',
           icon: trophy
        });

    toast.present();

}

export function getAchievements(){
    return Object.entries(get(achievementStore)).map(([key, achievement]) => ({ key, ...achievement }))
}

export async function initializeAchievementEngine(){
    await fivePassedAchievement();
}