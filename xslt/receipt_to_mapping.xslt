<?xml version="1.0"?>
<xsl:stylesheet 
  version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
>
<!--

  This stylesheet is used to transform the receipt from ENA's rest service to
  a tsv format which can be parsed by the script scripts/insert_values_from_ENA.pl.

-->
<xsl:strip-space elements="*" />
<xsl:output method="text" indent="no" />

<xsl:variable name="newline">
<xsl:text>
</xsl:text>
</xsl:variable>

<xsl:variable name="tab">
<xsl:text>	</xsl:text>
</xsl:variable>


<xsl:template match="/RECEIPT">

    <xsl:text>- Study identifiers:</xsl:text>
    <xsl:value-of select="$newline" />
    <xsl:value-of select="$newline" />
    <xsl:apply-templates select="STUDY" />
    <xsl:value-of select="$newline" />

    <xsl:text>- Submission identifiers:</xsl:text>
    <xsl:value-of select="$newline" />
    <xsl:value-of select="$newline" />
    <xsl:apply-templates select="SUBMISSION" />
    <xsl:value-of select="$newline" />

    <xsl:text>- Sample identifiers:</xsl:text>
    <xsl:value-of select="$newline" />
    <xsl:value-of select="$newline" />
    <xsl:apply-templates select="SAMPLE" />
    <xsl:value-of select="$newline" />

    <xsl:text>- Experiment identifiers:</xsl:text>
    <xsl:value-of select="$newline" />
    <xsl:value-of select="$newline" />
    <xsl:apply-templates select="EXPERIMENT" />
    <xsl:value-of select="$newline" />

    <xsl:text>- Run identifiers:</xsl:text>
    <xsl:value-of select="$newline" />
    <xsl:value-of select="$newline" />
    <xsl:apply-templates select="RUN" />
    <xsl:value-of select="$newline" />

</xsl:template>

<xsl:template match="STUDY">

  <xsl:text>ENA_accession_for_</xsl:text><xsl:value-of select="@alias" /><xsl:text>_study_goes_here</xsl:text>
  <xsl:value-of select="$tab" />
  <xsl:value-of select="@accession" />
  <xsl:value-of select="$newline" />
  
  <xsl:text>study_private_until</xsl:text>  
  <xsl:value-of select="$tab" />
  <xsl:value-of select="@holdUntilDate" />
  <xsl:value-of select="$newline" />
  
</xsl:template>

<xsl:template match="SUBMISSION">
  <xsl:text>ENA_accession_for_</xsl:text><xsl:value-of select="@alias" /><xsl:text>_submission_goes_here</xsl:text>
  <xsl:value-of select="$tab" />
  <xsl:value-of select="@accession" />
  <xsl:value-of select="$newline" />
</xsl:template>

<xsl:template match="SAMPLE">

    <xsl:text>ENA_accession_for_</xsl:text><xsl:value-of select="@alias" /><xsl:text>_goes_here</xsl:text>
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@accession" />
    <xsl:value-of select="$newline" />
    
    <xsl:text>ENA_external_accession_for_</xsl:text><xsl:value-of select="@alias" /><xsl:text>_goes_here</xsl:text>
    <xsl:value-of select="$tab" />
    <xsl:value-of select="EXT_ID/@accession" />
    <xsl:text> (</xsl:text>
    <xsl:value-of select="EXT_ID/@type" />
    <xsl:text>)</xsl:text>
    <xsl:value-of select="$newline" />

</xsl:template>

<xsl:template match="EXPERIMENT">

    <xsl:text>ENA_accession_for_</xsl:text><xsl:value-of select="@alias" /><xsl:text>_goes_here</xsl:text>
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@accession" />
    <xsl:value-of select="$newline" />
    
</xsl:template>

<xsl:template match="RUN">

    <xsl:text>ENA_accession_for_</xsl:text><xsl:value-of select="@alias" /><xsl:text>_goes_here</xsl:text>
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@accession" />
    <xsl:value-of select="$newline" />

</xsl:template>

</xsl:stylesheet>
