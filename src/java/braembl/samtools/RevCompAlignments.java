package braembl.samtools;

import htsjdk.samtools.Cigar;
import htsjdk.samtools.CigarElement;
import htsjdk.samtools.SAMFileHeader;
import htsjdk.samtools.SAMFileWriter;
import htsjdk.samtools.SAMFileWriterFactory;
import htsjdk.samtools.SAMReadGroupRecord;
import htsjdk.samtools.SAMRecord;
import htsjdk.samtools.SAMRecordIterator;
import htsjdk.samtools.SamReader;
import htsjdk.samtools.SamReaderFactory;
import htsjdk.samtools.ValidationStringency;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.GnuParser;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.apache.commons.io.FileUtils;
import org.biojava3.core.sequence.DNASequence;


public class RevCompAlignments {
	
	public File getRevcomp() {
		return revcomp;
	}

	public void setRevcomp(File revcomp) {
		this.revcomp = revcomp;
	}

	public File getOut() {
		return out;
	}

	public void setOut(File out) {
		this.out = out;
	}

	public File getBam() {
		return bam;
	}

	public void setBam(File bam) {
		this.bam = bam;
	}

	protected File revcomp;
	protected File out;	
	protected File bam;
	
	public static void main(String[] argv) {
    	
    	final RevCompAlignments t = new RevCompAlignments();    	
    	
    	Options options = new Options();    	
    	options.addOption("revcomp", true, "A text file with the names of all transcripts whose alignments should be reverse complemented.");
    	options.addOption("sam", true, "Sam file with buld instructions");
    	options.addOption("out", true, "Name of sam file to be created");
    	options.addOption("help", false, "Print help");
    	
    	CommandLineParser parser = new GnuParser();
    	CommandLine cmd = null;
		try {
			cmd = parser.parse( options, argv);
		} catch (ParseException e) {
			e.printStackTrace();
			System.exit(1);
		}
		
		boolean parameterMissing = false;    	

    	if(cmd.hasOption("help")) {

    		HelpFormatter formatter=new HelpFormatter();
    	    formatter.setWidth(Integer.MAX_VALUE);
    	    formatter.printHelp("./scripts/sam/select_alignments_from_sam.pl", options, true);
    	    System.exit(0);

    	}
    	if(cmd.hasOption("revcomp")) {
    		System.out.println("revcomp=" + cmd.getOptionValue("revcomp"));
    	    t.setRevcomp(new File(cmd.getOptionValue("revcomp")));
    	} else {
    		System.err.println("The parameter revcomp has not been set"); 
    	    parameterMissing = true;
    	}
    	if(cmd.hasOption("sam")) {
    		System.out.println("sam=" + cmd.getOptionValue("sam"));
    	    t.setBam(new File(cmd.getOptionValue("sam")));
    	} else {
    		System.err.println("The parameter bam has not been set"); 
    	    parameterMissing = true;
    	}
    	if(cmd.hasOption("out")) {
    		System.out.println("out=" + cmd.getOptionValue("out"));
    	    t.setOut(new File(cmd.getOptionValue("out")));
    	} else {
    		System.err.println("The parameter out has not been set, setting to default out.sam");
    		t.setOut(new File("out.sam"));
    	}
    	if (parameterMissing) {
    		System.exit(1);
    	}
    	t.run();    	
    }

	public void run() {

    	System.out.println("Starting creation of sam file");
    	String readGroupRecordId = "defaultReadGroup";
    	
    	List <String> allTranscripts = readTranscriptNames(getRevcomp());

    	final SamReader assemblyBuildInstructionsBamReader = SamReaderFactory.makeDefault().validationStringency(ValidationStringency.STRICT).open(this.getBam());    	
    	
		// Header is copied over, because all alignments are included in the 
		// newly generated file.
		//
    	SAMFileHeader samFileHeader = assemblyBuildInstructionsBamReader.getFileHeader();
    	
    	// Prevent error: "@RG line missing SM tag."    	
    	if (samFileHeader.getReadGroup(readGroupRecordId) == null) {    		
    		SAMReadGroupRecord srgr = new SAMReadGroupRecord(readGroupRecordId);
	    	srgr.setSample("default sample");	    	
	    	samFileHeader.addReadGroup(srgr);
    	}    	

    	final SAMFileWriter outputSam = new SAMFileWriterFactory().makeSAMWriter(
        	samFileHeader,
            false, 
            out
        );
		       
    	SAMRecordIterator assemblyBuildInstructionsBamRecordIterator = assemblyBuildInstructionsBamReader.iterator();

    	HashSet<String> revcomAlignmentSet = new HashSet<String>();
    	revcomAlignmentSet.addAll(allTranscripts);    	    	
    	
    	while (assemblyBuildInstructionsBamRecordIterator.hasNext()) {
    		
    		SAMRecord assemblyBuildInstructionsBamRecord = assemblyBuildInstructionsBamRecordIterator.next();    		
    		String currentContig = assemblyBuildInstructionsBamRecord.getReferenceName();
    		
    		int referenceLength = samFileHeader.getSequence(currentContig).getSequenceLength();
    		
    		boolean reverseComplementThisSamRecord = revcomAlignmentSet.contains( currentContig );
    		
    		if (reverseComplementThisSamRecord) {
    			
    			int alignmentStart = assemblyBuildInstructionsBamRecord.getAlignmentStart();
    			
        		assemblyBuildInstructionsBamRecord.setReadNegativeStrandFlag( ! assemblyBuildInstructionsBamRecord.getReadNegativeStrandFlag() );            		
        		assemblyBuildInstructionsBamRecord.setReadString(
        			new DNASequence( assemblyBuildInstructionsBamRecord.getReadString() ).getReverseComplement().getSequenceAsString()
        		);
        		assemblyBuildInstructionsBamRecord.setAlignmentStart(
        				referenceLength - alignmentStart +1	            				
        				- assemblyBuildInstructionsBamRecord.getCigar().getReferenceLength() +1
        		);
        		
        		List<CigarElement> ce = new ArrayList<CigarElement>(assemblyBuildInstructionsBamRecord.getCigar().getCigarElements());	            		
        		Collections.reverse( ce );
        		assemblyBuildInstructionsBamRecord.setCigar( new Cigar(ce) );
    		}
    		assemblyBuildInstructionsBamRecord.setAttribute(SAMReadGroupRecord.READ_GROUP_ID_TAG, readGroupRecordId);
    		outputSam.addAlignment(assemblyBuildInstructionsBamRecord);    		
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
