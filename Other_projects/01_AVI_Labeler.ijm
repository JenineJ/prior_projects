// AVI Labeler Action Bar v1.1

run("Action Bar","/plugins/ActionBar/AVI_Labeler.ijm");
exit;

//print("\\Clear") 		//clears log
//<onTop>    			//keeps ActionBar window always on top of others

<text> Labeling Actions

<line>

<button> help
label=Help
icon=noicon
arg=<macro>
	showMessage("AVI Labeler Help", "" +
	"AVI LABELER v1.1 HELP \n \n " +
	"    LABELING \n \n" +
	"         AVI files must first be processed (placed into a new folder with the name of the AVI) using one of the options below: \n" +
	"              - \"Choose Directory\" followed by using \"Process Next AVI\" as many times as needed\n" +
	"              - \"Choose AVI to Process\" \n \n" +
	"         Draw desired polygon. If you accidentally click outside of the polygon and it disappears, click \"Undo Selection Delete\" to restore. \n" +
	"             To close the polygon, either click on the first point or double-click on the last point. \n" +
	"             Adjust polygon by dragging the points. Shift + click on a point to split it into two, giving you more points to adjust (it also smooths out the shape). \n \n" +
	"         Once the polygon is complete, click the appropriate label in \"Labels\". This will add the ROI to the ROI manager. \n" +
	"             Sometimes the label does not show up in the ROI Manager right away- it may help to click an ROI within the ROI Manager. \n" +
	"             If the ROI Manager is not open, select Analyze->Tools->Roi Manager... in the menu bar. \n" +
	"             The ROI Manager tools can also be used to work with the ROIs. \n \n" +
	"             It can be helpful to use the \"Show All\" option- for example to check whether the labels within a frame or between frames make sense with each other. \n" +
	"         If you are uncertain about an ROI, select the ROI in the ROI Manager and click \"Mark as Unclear\". This will add \"-unclear\" to the ROI name.\n \n" +
	"         Once you are done, click \"Save ROIs\" (this will save the XY coordinates of each ROI to the folder that the AVI was opened from, and add). \n" +
	"            \"unclear.\" to the beginning of the folder name if any ROIs were marked as unclear \n \n " +
	"    REVIEWING \n \n" +
	"         To open an AVI with its labels, select \"Open Folder\" and select a folder that contains these files. \n \n" +
	"         If an editor marks the folder as one that you should review, it will have \"edited.\" at the beginning of the folder name. You should: \n" +
	"              - Open the folder \n" +
	"              - Compare your ROIs (marked with \"-old\" at the end of the ROI name) to the new ones \n" +
	"              - Click \"Mark Edits as Reviewed\" to delete the ROIs marked as \"-old\", remove \"edited.\" from the folder name, and place into the \"Checked\" folder. \n" +
	"                   - If you have questions on the ROIs, skip this step and discuss with the editor before completing. \n \n" +
	"    EDITING- FOR EDITORS ONLY \n \n" +
	"         To open an AVI with its labels, select \"Open Folder\" and select a folder that contains these files. \n \n" +
	"         To adjust an ROI: \n" +
	"              - Click on \"Change ROI\" first. This will duplicate the ROI and then add \"-old\" to the end of the old ROI's name \n" +
	"              - Adjust the new ROI (it will be automatically selected), then click \"Update\" in the ROI manager. \n" +
	"              - *Of note, if you decide not to create an ROI for a frame that the labeler chose, the prior ROI must be manually deleted from the folder* \n \n" +
	"         After reviewing, either: \n \n" +
	"              - Click \"Save Checked/Edited ROIs\"- this will remove \"-unclear\" from the end of any ROIs, save all the ROIs without \"-old\" at the end, and \n" +
	"                   delete \"unclear.\" from the beginning of the folder name if present. Files will be saved in a folder called \"Checked\". \n" +
	"              - Click \"Save ROIs, Mark as Edited\"- this will remove \"-unclear\" from the end of any ROIs, save all the ROIs (including the old ones), \n" +
	"                   delete \"unclear.\" from the beginning of the folder name if present, and add \"edited.\" to the beginning of the folder name, so that \n" +
	"                   labelers can tell which folders need to be reviewed.  \n \n" +
	"    OTHER \n \n" +
	"         Click \"Show Folder\" to open the folder that the AVI was opened from. This can be used to check the ROIs and manually delete ROIs if needed. " +
	" ");

</macro>


<button> choose_directory
label=Choose Directory 
icon=noicon
arg=<macro>
	inputdir = getDirectory("Choose a Directory");
	call("ij.Prefs.set", "avi_labeling.inputdir", inputdir);      //allows the variable to be accessed in the next macro
	//showMessage("Chosen directory: " + inputdir);
</macro>




<button> process_next_avi
label= Process Next AVI
icon=noicon
arg=<macro>
//finds the first avi file, then creates a folder and moves the avi file into it, then opens the file
	inputdir = call("ij.Prefs.get", "avi_labeling.inputdir", "")
	filelist = getFileList(inputdir);
	avifilelist = newArray(filelist.length);

	if(inputdir=="") {
		showMessage("Please choose a directory first");
	}

	else {
		
		count=0;

		for(i=0; i<filelist.length; i++) {
			if(endsWith(filelist[i], ".avi")) {
				avifilelist[count] = filelist[i];
				count++;
			}	
		}

		if(count>0) {

			newdirname = replace(avifilelist[0], ".avi", "");
			File.makeDirectory(inputdir + newdirname);
			File.rename(inputdir + avifilelist[0], inputdir + newdirname + File.separator + avifilelist[0]); 
			open(inputdir + newdirname + File.separator + avifilelist[0]);
			run("ROI Manager...");
			setTool("polygon");
			roiManager("Show All");
		}

		else {
			showMessage("No AVI files in folder");
		}
	}
</macro>


</line>
<line>


<button> choose_avi_to_process
label= Choose AVI to Process 
icon=noicon
arg=<macro>
	chosenavi = File.openDialog("Select AVI file");
	chosenavi_path = File.getParent(chosenavi);
	chosenavi_name = File.getName(chosenavi);

	if(endsWith(chosenavi_name, ".avi")==false) {
		showMessage("Please choose an AVI file")ok 
	}

	else {
		newdirname = replace(chosenavi_name, ".avi", "");
		File.makeDirectory(chosenavi_path + File.separator + newdirname);
			File.rename(chosenavi_path + File.separator + chosenavi_name, chosenavi_path + File.separator + newdirname + File.separator + chosenavi_name); 
			open(chosenavi_path + File.separator + newdirname + File.separator + chosenavi_name);
			run("ROI Manager...");
			setTool("polygon");
			roiManager("Show All");
	}
</macro>


<button> undo_selection_delete
label= Undo Selection Delete
icon=noicon
arg=<macro>
	run("Restore Selection");
</macro>



</line>
<line>


<button> mark_unclear
label= Mark as Unclear
icon=noicon
arg=<macro>
	roiManager("rename", Roi.getName + "-unclear")
</macro>



<button> save_rois
label= Save ROIs
icon=noicon
arg=<macro>
	directoryname = getDirectory("image");
	pathname = File.getParent(getDirectory("image"));
	foldername = File.getName(getDirectory("image"));
	
	unclear = 0;
	
	roiManager("select", 0);
	for(i=0; i<roiManager("count"); i++) {
		roiManager("select", i);
		saveAs("XY Coordinates", directoryname + foldername + "_" + call("ij.plugin.frame.RoiManager.getName", i) + ".txt");
		if(matches(call("ij.plugin.frame.RoiManager.getName", i), ".*-unclear")==1) {
			unclear = 1;
		}
	}
	
	if(unclear==1) {
		if(startsWith(foldername, "unclear.")==false) {
			newfoldername = "unclear." + foldername;
			File.rename(pathname + File.separator + foldername, pathname + File.separator + newfoldername);
		}
	}

	roiManager("Deselect");
	roiManager("Delete");	
	close();
</macro>







</line>


<text> Labels 

<line>

<button> label_psax_i
label= Label PSAX _i
icon=noicon
arg=<macro>
	roiManager("add");
	roiManager("select", roiManager("count") - 1);
	Stack.getPosition(channel, slice, frame);
	roiManager("rename", slice + "_i");
	roiManager("deselect");
</macro>



<button> label_psax_o
label= Label PSAX _o
icon=noicon
arg=<macro>
	roiManager("add");
	roiManager("select", roiManager("count") - 1);
	Stack.getPosition(channel, slice, frame);
	roiManager("rename", slice + "_o");
	roiManager("deselect");
</macro>


</line>
<line>


<button> label_a4c_la
label= Label A4C _la
icon=noicon
arg=<macro>
	roiManager("add");
	roiManager("select", roiManager("count") - 1);
	Stack.getPosition(channel, slice, frame);
	roiManager("rename", slice + "_la");
	roiManager("deselect");
</macro>



<button> label_a4c_ra
label= Label A4C _ra
icon=noicon
arg=<macro>
	roiManager("add");
	roiManager("select", roiManager("count") - 1);
	Stack.getPosition(channel, slice, frame);
	roiManager("rename", slice + "_ra");
	roiManager("deselect");
</macro>


</line>
<line>


<button> label_a4c_ilv
label= Label A4C _ilv
icon=noicon
arg=<macro>
	roiManager("add");
	roiManager("select", roiManager("count") - 1);
	Stack.getPosition(channel, slice, frame);
	roiManager("rename", slice + "_ilv");
	roiManager("deselect");
</macro>



<button> label_a4c_olv
label= Label A4C _olv
icon=noicon
arg=<macro>
	roiManager("add");
	roiManager("select", roiManager("count") - 1);
	Stack.getPosition(channel, slice, frame);
	roiManager("rename", slice + "_olv");
	roiManager("deselect");
</macro>


</line>
<line>

<button> label_a4c_irv
label= Label A4C _irv
icon=noicon
arg=<macro>
	roiManager("add");
	roiManager("select", roiManager("count") - 1);
	Stack.getPosition(channel, slice, frame);
	roiManager("rename", slice + "_irv");
	roiManager("deselect");
</macro>


<separator>


</line>

<text> Review 

<line>


<button> open_folder
label=Open Folder
icon=noicon
arg=<macro>

	folderdir = getDirectory("Choose a Directory");
	filelist = getFileList(folderdir);


	//Opens AVI file
	avifile = "";

	for(i=0; i<filelist.length; i++) {
		if(endsWith(filelist[i], ".avi")) {
			if(avifile=="") {
				avifile = filelist[i];
				open(folderdir + avifile);
			}
			else {
				showMessage("Warning: Folder contains more than one AVI file")
			}
		}
	}


	//Opens .txt ROI files
	roiManager("Show All");
	roiManager("Associate", "true");
	
	for(i=0; i<filelist.length; i++) {
		if(endsWith(filelist[i], ".txt")) {
			run("XY Coordinates... ", "open=[" + folderdir + filelist[i] + "]");

			roiManager("add");
			roiManager("select", (roiManager("count") - 1));

			
			filenameall = split(filelist[i],".");
			filenametext = split(filenameall[0], "_");
			filenamesize = lengthOf(filenametext);
			filenameend = filenametext[filenamesize - 2] + "_" + filenametext[filenamesize - 1];
			roiManager("Rename", filenameend);
			
			roislice = filenametext[filenamesize - 2];

			run("Properties... ", "name=" + (call("ij.plugin.frame.RoiManager.getName", (roiManager("count")-1))) + " position=" + roislice);  
		}	
	}

	roiManager("Sort");

		
</macro>


<button> close_folder
label=Close Folder
icon=noicon
arg=<macro>
	roiManager("Deselect");
	roiManager("Delete");	
	close();
</macro>


</line>
<line>

<button> mark_edits_as_reviewed
label=Mark Edits as Reviewed
icon=noicon
arg=<macro>

	pathname = File.getParent(getDirectory("image"));
	foldername = File.getName(getDirectory("image"));
	if(startsWith(foldername, "edited.")) {
		foldernameparts = split(foldername, ".");
		newfoldername = foldernameparts[1];
		

		for(i=0; i<roiManager("count"); i++) {
			roiManager("select", i);
			rname = call("ij.plugin.frame.RoiManager.getName", i);

			if((matches(rname, ".*-old")==1)||matches(rname, ".*-unclear.*")==1) {
				File.delete(pathname + File.separator + foldername + File.separator + newfoldername + "_" + rname + ".txt");
			}
		}

		File.rename(pathname + File.separator + foldername, pathname + File.separator + newfoldername);

		checkedfolder = pathname + File.separator + "Checked";

		if(matches(pathname, ".*Checked")==0) {
			if (!File.exists(checkedfolder))
				File.makeDirectory(checkedfolder);

			File.rename(pathname + File.separator + newfoldername, checkedfolder + File.separator + newfoldername);
		}


		roiManager("Deselect");
		roiManager("Delete");
		close();
	}

	else {
		showMessage("File was not marked as edited");
	}
</macro>

<separator>
</line>

<text> Edit

<line>


<button> open_folder2
label=Open Folder
icon=noicon
arg=<macro>
	Dialog.create("Choose a folder with one AVI file and labels");
	folderdir = getDirectory("Choose a Directory");
	filelist = getFileList(folderdir);
	
	//Opens AVI file
	avifile = "";

	for(i=0; i<filelist.length; i++) {
		if(endsWith(filelist[i], ".avi")) {
			avifile = filelist[i];
			//print("adding to avifile: " + avifile);
		}
	}
	open(folderdir + avifile);

	//Opens .txt ROI files
	pathname = File.getParent(getDirectory("image"));
	//print("Pathname is " + pathname);


	roiManager("Show All");
	roiManager("Associate", "true");
	
	for(i=0; i<filelist.length; i++) {
		if(endsWith(filelist[i], ".txt")) {
			run("XY Coordinates... ", "open=[" + folderdir + filelist[i] + "]");

			roiManager("add");
			roiManager("select", (roiManager("count") - 1));

			
			filenameall = split(filelist[i],".");
			filenametext = split(filenameall[0], "_");
			filenamesize = lengthOf(filenametext);
			filenameend = filenametext[filenamesize - 2] + "_" + filenametext[filenamesize - 1];
			roiManager("Rename", filenameend);
			
			roislice = filenametext[filenamesize - 2];

			run("Properties... ", "name=" + (call("ij.plugin.frame.RoiManager.getName", (roiManager("count")-1))) + " position=" + roislice);  
			
		}	
	}	

	roiManager("Sort");
	setTool("polygon");
</macro>


<button> close_folder2
label=Close Folder
icon=noicon
arg=<macro>
	roiManager("Deselect");
	roiManager("Delete");	
	close();
</macro>


</line>
<line>

<button> change_roi
label=Change ROI
icon=noicon
arg=<macro>
	selectedindex = roiManager("index");
	rname = call("ij.plugin.frame.RoiManager.getName", selectedindex);
	rname_withoutunclear = replace(rname, "-unclear", "");
	roiManager("rename", rname + "-old");
	roiManager("Add");
	roiManager("select", (roiManager("count") - 1));
	roiManager("rename", rname_withoutunclear);

</macro>





<button> save_checked_edited_rois
label=Save Checked/Edited ROIs
icon=noicon
arg=<macro>
	pathname = File.getParent(getDirectory("image"));
	foldername = File.getName(getDirectory("image"));
	filelist = getFileList(getDirectory("image"));
	foldernamebase = foldername;

	if(startsWith(foldername, "unclear.")) {
		foldernameparts = split(foldername, ".");
		foldernamebase = foldernameparts[1];
	}


	for(i=0; i<roiManager("count"); i++) {
		roiManager("select", i);
		roiManager("Update");
		rname = call("ij.plugin.frame.RoiManager.getName", i);
		rname_withoutunclear = replace(rname, "-unclear", "");
		if(matches(rname, ".*-old")==0) {
			saveAs("XY Coordinates", pathname + File.separator + foldername + File.separator + foldernamebase + "_" + rname_withoutunclear + ".txt");
		}
	}

	for(i=0; i<filelist.length; i++) {
		if(endsWith(filelist[i], ".txt")) {
			if(matches(filelist[i], ".*-unclear.*")==1) {
				File.delete(pathname + File.separator + foldername + File.separator + filelist[i]);
			}
		}
	}


	//print("foldername is " + foldername);
	//print("directory is " + getDirectory("image"));
	//print("done folder is" + checkedfolder);

	if(startsWith(foldername, "unclear.")) {
		File.rename(getDirectory("image"), pathname + File.separator + foldernamebase);
	}
	
	checkedfolder = pathname + File.separator + "Checked";

	if(matches(pathname, ".*Checked")==0) {
		if (!File.exists(checkedfolder))
			File.makeDirectory(checkedfolder);
		File.rename(pathname + File.separator + foldernamebase, checkedfolder + File.separator + foldernamebase);
	}


	roiManager("Deselect");
	roiManager("Delete");
	close();
	//run("Image");
</macro>


</line>
<line>
	





<button> save_mark_as_edited
label=Save ROIs, Mark as Edited
icon=noicon
arg=<macro>

	pathname = File.getParent(getDirectory("image"));
	foldername = File.getName(getDirectory("image"));
	filelist = getFileList(getDirectory("image"));
	foldernamebase = foldername;

	if(startsWith(foldername, "unclear.")) {
		foldernameparts = split(foldername, ".");
		foldernamebase = foldernameparts[1];
	}


	
	for(i=0; i<roiManager("count"); i++) {
		roiManager("select", i);
		roiManager("Update");
		rname = call("ij.plugin.frame.RoiManager.getName", i);
		rname_withoutunclear = replace(rname, "-unclear", "");
		saveAs("XY Coordinates", pathname + File.separator + foldername + File.separator + foldernamebase + "_" + rname_withoutunclear + ".txt");
	}


	for(i=0; i<filelist.length; i++) {
		if(endsWith(filelist[i], ".txt")) {
			if(matches(filelist[i], ".*-unclear.txt")==1) {
				File.delete(pathname + File.separator + foldername + File.separator + filelist[i]);
			}
		}
	}

	if(startsWith(foldername, "unclear.")) {
		File.rename(getDirectory("image"), pathname + File.separator + foldernamebase);
	}


	if(startsWith(foldername, "edited.")==true) {
		showMessage("File was already marked as edited");
		close();	
	}
	
	else {
		newfoldername = "edited." + foldernamebase;
		close();
		File.rename(pathname + File.separator + foldernamebase, pathname + File.separator + newfoldername);
	}

	roiManager("Deselect");
	roiManager("Delete");
	
</macro>

<separator>

</line>

<text> Other




<line>

<button> show_folder
label=Show Folder
icon=noicon
arg=<macro>
	//print(getDirectory("image"));
	run("Image");
</macro>

</line>


