var resizeFlag = true;

// This function runs when the "Current" button is pressed to ignore
// the input from the time fields.  
function disableTime() {
	if (document.all || document.getElementById){
		document.graphCfg.YEAR.disabled=true;
		document.graphCfg.MONTH.disabled=true;
		document.graphCfg.DAY.disabled=true;
		document.graphCfg.HOUR.disabled=true;
	}
}

// Resize canvas to fit screen.
function resizeCanvas() {
	var canvas = document.getElementById("graph");
	var ctx = canvas.getContext("2d");
	ctx.canvas.width  = window.innerWidth*.95;
	ctx.canvas.height = window.innerHeight*.95;
	return true;
}

// returns the tooltip for datapoint i.  RGraph calls this for each point
function getTooltip(i) {
	return tips[i];
}
// Like above for labels
function getLabel(i) {
	return i;
}

// Array for the tooltips;
var tips = new Array;

// This is the meat of the program where RGraph is called to generate the graph
// If this is all operational you should be able to find the documentation for
// RGraph at http://127.0.0.1/lib/RGraph/
function graphData(data,unit,title,key,color,ymin_def,ymax_def) {


	// Resize the canvas on first time through
	if (resizeFlag) {
		resizeFlag = resizeCanvas();
	}

	// Create array for tooltips and get min/max values too
	var ymin;
	var ymax;
	if (ymin_def != null) {
		ymin = ymin_def;
	}
	if (ymax_def != null) {
		ymax = ymax_def;
	}
	var t = 0;
	for (i=0;i<data.length;i++) {
		for (j=0;j<data[i].length;j++) {
			// minimum?
			if ( ymin == null || ymin > data[i][j]) {
				ymin = data[i][j];
				if (ymin != 0) {
					ymin--;
				}
			}
			// maximum?
			if ( ymax == null || ymax < data[i][j]) {
				ymax = data[i][j]+1;
			}
			// make tooltip 
			tips[t] = data[i][j];
			tips[t] = tips[t]+unit;	
			t++;

		}
	}

	// Create array for labels
	var labels = new Array;
	for (i=0;i<data[0].length;i++) {
		labels[i] = (i < 10) ? "0"+i : i;
	}
       	var line = new RGraph.Line('graph', data);
	
        line.Set('chart.title',title);
        line.Set('chart.key', key);
	line.Set('chart.key.position','gutter');
	line.Set('chart.key.position.gutter.boxed',true);
        line.Set('chart.key.position.y', line.canvas.height-15);
	line.Set('chart.units.post',unit);
	line.Set('chart.ymax', ymax);
	line.Set('chart.ymin', ymin);
	line.Set('chart.background.barcolor1', color['bg']);
	line.Set('chart.background.barcolor2', color['bg']);
	line.Set('chart.background.grid.color', color['fg']);
	line.Set('chart.colors', color['chart']);
        line.Set('chart.tickmarks', ['circle', 'square','square']);
        line.Set('chart.tooltips', getTooltip);
	line.Set('chart.tooltips.effect', 'snap');
	line.Set('chart.labels', labels);
	line.Set('chart.linewidth', 2);
	line.Set('chart.hmargin', 5);
	line.Set('chart.ylabels.inside',true);
	line.Set('chart.ylabels.inside.color','grey');
	line.Set('chart.gutter', 40);
	line.Set('chart.background.grid.autofit',true);
 	line.Set('chart.background.grid.autofit.numhlines',20);
	line.Set('chart.background.grid.autofit.numvlines',data[0].length-1);
	line.Draw();
}
