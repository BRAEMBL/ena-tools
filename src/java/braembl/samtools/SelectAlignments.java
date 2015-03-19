package braembl.samtools;
import htsjdk.samtools.SAMFileHeader;
import htsjdk.samtools.SAMFileWriter;
import htsjdk.samtools.SAMFileWriterFactory;
import htsjdk.samtools.SAMReadGroupRecord;
import htsjdk.samtools.SAMRecord;
import htsjdk.samtools.SAMRecordIterator;
import htsjdk.samtools.SAMSequenceRecord;
import htsjdk.samtools.SamReader;
import htsjdk.samtools.SamReaderFactory;
import htsjdk.samtools.ValidationStringency;

import java.io.File;
import java.io.IOException;
import java.util.HashSet;
import java.util.List;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.io.FileUtils;

public class SelectAlignments {

	protected File allTranscriptsFile;
	
	public File getAllTranscriptsFile() {
		return allTranscriptsFile;
	}
	
	protected File assemblyBuildInstructionsBamFile;
	
	public File getAssemblyBuildInstructionsBamFile() {
		return assemblyBuildInstructionsBamFile;
	}

	public void setAssemblyBuildInstructionsBamFile(
			File assemblyBuildInstructionsBamFile) {
		this.assemblyBuildInstructionsBamFile = assemblyBuildInstructionsBamFile;
	}

	public void setAllTranscriptsFile(File allTranscriptsFile) {
		this.allTranscriptsFile = allTranscriptsFile;
	}

	protected File outputBamFile;
	
    public File getOutputBamFile() {
		return outputBamFile;
	}

	public void setOutputBamFile(File outputBamFile) {
		this.outputBamFile = outputBamFile;
	}

	public static void main(String[] argv) {
    	
    	final SelectAlignments t = new SelectAlignments();    	
    	
    	Options options = new Options();    	
    	options.addOption("select", true, "A text file with the names of all transcripts that should be included into the build instructions.");
    	options.addOption("sam", true, "Sam file with buld instructions");
    	options.addOption("out", true, "Name of sam file to be created");    	
    	
    	CommandLineParser parser = new GnuParser();
    	CommandLine cmd = null;
		try {
			cmd = parser.parse( options, argv);
		} catch (ParseException e) {
			e.printStackTrace();
			System.exit(1);
		}
		
		boolean parameterMissing = false;    	

    	if(cmd.hasOption("select")) {
    		System.out.println("select=" + cmd.getOptionValue("select"));
    	    t.setAllTranscriptsFile(new File(cmd.getOptionValue("select")));
    	} else {
    		System.err.println("The parameter select has not been set"); 
    	    parameterMissing = true;
    	}
    	if(cmd.hasOption("sam")) {
    		System.out.println("sam=" + cmd.getOptionValue("sam"));
    	    t.setAssemblyBuildInstructionsBamFile(new File(cmd.getOptionValue("sam")));
    	} else {
    		System.err.println("The parameter bam has not been set"); 
    	    parameterMissing = true;
    	}
    	if(cmd.hasOption("out")) {
    		System.out.println("out=" + cmd.getOptionValue("out"));
    	    t.setOutputBamFile(new File(cmd.getOptionValue("out")));
    	} else {
    		System.err.println("The parameter out has not been set, setting to default out.sam");
    		t.setOutputBamFile(new File("out.sam"));
    	}
    	if (parameterMissing) {
    		System.exit(1);
    	}
    	t.run();    	
    }

	public void run() {

    	System.out.println("Starting creation of sam file");
    	String readGroupRecordId = "defaultReadGroup";
    	
    	List <String> allTranscripts = readTranscriptNames(this.getAllTranscriptsFile());

    	final SamReader assemblyBuildInstructionsBamReader = SamReaderFactory.makeDefault().validationStringency(ValidationStringency.STRICT).open(getAssemblyBuildInstructionsBamFile());    	
  	
    	SAMFileHeader samFileHeader = new SAMFileHeader();
    	for (String currentContigName : allTranscripts) {    		
        	SAMSequenceRecord ssr = assemblyBuildInstructionsBamReader.getFileHeader().getSequence(currentContigName).clone();
        	samFileHeader.addSequence(ssr);
    	}
    	
    	// Prevent error: "@RG line missing SM tag."
    	if (samFileHeader.getReadGroup(readGroupRecordId) == null) {    		
    		SAMReadGroupRecord srgr = new SAMReadGroupRecord(readGroupRecordId);
	    	srgr.setSample("default sample");	    	
	    	samFileHeader.addReadGroup(srgr);
    	}

    	final SAMFileWriter outputSam = new SAMFileWriterFactory().makeSAMWriter(
        	samFileHeader,
            true, 
            outputBamFile
        );
        
    	SAMRecordIterator assemblyBuildInstructionsBamRecordIterator = assemblyBuildInstructionsBamReader.iterator();

    	HashSet<String> allTranscriptsSet = new HashSet<String>();
    	allTranscriptsSet.addAll(allTranscripts);    	    	
    	
    	while (assemblyBuildInstructionsBamRecordIterator.hasNext()) {
    		
    		SAMRecord assemblyBuildInstructionsBamRecord = assemblyBuildInstructionsBamRecordIterator.next();    		
    		String currentContig = assemblyBuildInstructionsBamRecord.getReferenceName();    		
    		boolean includeThisSamRecord = allTranscriptsSet.contains( currentContig ); 
    		
    		if (includeThisSamRecord) {
    			assemblyBuildInstructionsBamRecord.clearAttributes();
        		assemblyBuildInstructionsBamRecord.setAttribute(SAMReadGroupRecord.READ_GROUP_ID_TAG, readGroupRecordId);
        		outputSam.addAlignment(assemblyBuildInstructionsBamRecord);
    		}    		
    	}
    	
    	try {
    		outputSam.close();
			assemblyBuildInstructionsBamReader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private List<String> readTranscriptNames(File reverseTranscriptsFile) {
		List<String> reverseTranscriptsList = null;
    	try {
			reverseTranscriptsList = FileUtils.readLines(reverseTranscriptsFile);
		} catch (IOException e1) {
			e1.printStackTrace();
			System.exit(1);
		}
    	return reverseTranscriptsList;
	}
}
