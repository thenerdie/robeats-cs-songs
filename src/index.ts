interface AudioDifficulty {
	Overall: number;
	Chordjack: number;
	Handstream: number;
	Jack: number;
	Jumpstream: number;
	Stamina: number;
	Stream: number;
	Technical: number;
	Rate: number;
}

interface HitObject {
	Duration?: number;
	Time: number;
	Track: number;
	Type: number;
}

interface AudioFile {
	AudioArtist: string;
	AudioAssetId: string;
	AudioCoverImageAssetId: string;
	AudioDescription: string;
	AudioDifficulty: AudioDifficulty[];
	AudioFilename: string;
	AudioHitSFXGroup: number;
	AudioMapper: string;
	AudioMod: number;
	AudioNotePrebufferTime: number;
	AudioTimeOffset: number;
	AudioVolume: number;
	AudioMD5Hash: string;
	HitObjects: HitObject[];
}

const files: AudioFile[] = [];

function loadSongs() {}

loadSongs();

// script.Parent?.WaitForChild("songs").

export function makeHello(name: string) {
	return `Hello from ${name}!`;
}
