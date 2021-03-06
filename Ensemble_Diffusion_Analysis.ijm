//Example macro that does a diffusion analysis on a results table of tracking 
//data. The required format is as generated by the Manual Tracking plugin 
//http://rsbweb.nih.gov/ij/plugins/track/track.html
//assuming Results table column headings: Track > Slice > X > Y
//It requires many tracks and many time points!
//The analysis uses the time ensemble average method described in Charsooghi, MA et al 2011
//http://www.sciencedirect.com/science/article/pii/S0010465510003620

//calibration
timestep = 10; //time in minutes between frames
cal = 0.619; //um per pixel

//get the track numbers in an array to use as the index
track_number = list_no_repeats ("Results", "Track");

//get number of tracks (nTracks)
nTracks = track_number.length;

//Index the tracks numerically will be the same as "Track" if strings are not used
index = 1;

for (l=0; l<nResults; l++) {
	if (l==0) {
		setResult("Index", l, index);
	}
	else if (getResultString("Track", l) == getResultString("Track",l-1)) {
		setResult("Index", l, index);
	}
	else if (getResult("Track", l) != getResult("Track",l-1)) {
		index = index+1;
		setResult("Index", l, index);
	}
}

//Workout the window size from the track lengths and write lengths to table
lengths = get_track_lengths();
Array.getStatistics(lengths, min, max, mean, stdDev);

//The window sizes for analysis range from 1 to max-1
//Calculate squared dispalcement from tracking data for all possible window sizes 

MSD = newArray();
time = newArray();
divide = 0;
r_total = 0;
distance = 0;

//Iterate through the different window sizes from 1 to maxslice
for (u=1; u<max; u++) {

//For each window iterate through the results table
	for (i=0; i<nResults(); i++){

//If the frame number is less than or equal to the window size
		if (getResult("Step", i) <= u) {}
	
		else { if (getResult("Index", i)>getResult("Index", i-u)) {}
	
		else { if (getResult("T_Length", i)>=u && getResult("Index", i-u)==getResult("Index", i)) {
			x = getResult("X", i);
			x1 = getResult("X", i-u);
			y = getResult("Y", i);
			y1 = getResult("Y", i-u);
			distance = get_pythagoras(x, y, x1, y1, cal);
			r_total = r_total+(distance*distance);	
			divide++;
			}	
		}
	}
}

time = Array.concat(time, u * timestep);	
MSD = Array.concat(MSD, (r_total)/divide);
r_total=0;
divide=0;
}

//Trim the msd array to the max values before fitting
arraymax = 0;
msd2 = newArray();
time2 = newArray();
var done = false;
for (i=1; i<MSD.length && !done; i++) {
	if (MSD[i]>MSD[i-1])  {
		msd2 = Array.concat(msd2, MSD[i]);
		time2 = Array.concat(time2, time[i]);
		
	} else {
		done = true;
	}
}

Array.print(time2);
Array.print(msd2);
Fit.doFit("Straight Line", time2, msd2);
intercept = d2s(Fit.p(0),6);
slope = d2s(Fit.p(1),6);
r2 = d2s(Fit.rSquared,3);
//dc = (slope/4);

print("slope = "+slope);
print("intercept = "+intercept);
print("R^2 = "+r2);
//print("D = "+D);

Fit.plot();
Plot.setFrameSize(400, 400);

function list_no_repeats (table, heading) {
//Returns an array of the entries in a column without repeats to use as an index

//Check whether the table exists
	if (isOpen(table)) {

//get the entries in the column without repeats
		no_repeats = newArray(getResultString(heading, 0));

		for (i=0; i<nResults; i++) {
			occurence = getResultString(heading, i);
			for (j=0; j<no_repeats.length; j++) {
				if (occurence != no_repeats[j]) {
					flag = 0;
				} else {
						flag = 1;
					}
				}
			
			if (flag == 0) {
				occurence = getResultString(heading, i);
				no_repeats = Array.concat(no_repeats, occurence);	
			}
		}
	} else {
		Dialog.createNonBlocking("Error");
		Dialog.addMessage("No table with the title "+table+" found.");
		Dialog.show();
	}
	return no_repeats;
}


function get_pythagoras(x, y, x1, y1, scale) {
//get the distance between x,y and x1,y1 in the usual way use scale to convert to real world units
	x2 = x - x1;
	y2 = y - y1;
    distance = (sqrt((x2*x2)+(y2*y2)))*scale;
	return distance;
}

function get_track_lengths() {
//get the track lengths in an and array write them to the table
	track_number = list_no_repeats ("Results", "Track");

//get track lengths in array and write to results
	track_lengths = newArray();
	for (a=0; a<track_number.length; a++){
		t_le = 0;
		for (i=0; i<nResults; i++) {
			if (getResultString("Track",i) == toString(track_number[a])) {
				t_le = t_le +1;
			}
		}
		track_lengths = Array.concat(track_lengths, t_le);
	}
		
		for (a=0; a<track_number.length; a++){
			frame=0;
		for (i=0; i<nResults; i++) {
			if (getResultString("Track",i) == toString(track_number[a])) {
				frame=frame+1;
				setResult("T_Length", i, track_lengths[a]);
				setResult("Step", i, frame);
			}
		}
	}

	return track_lengths;
}