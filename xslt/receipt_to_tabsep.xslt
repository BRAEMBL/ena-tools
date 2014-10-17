<?xml version="1.0"?>
<xsl:stylesheet 
  version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
>
<!--

  This stylesheet is used to transform the xml output from interproscan to
  a customised tsv output for importing go annotations.


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
    <xsl:apply-templates select="STUDY" />

    <xsl:text>- Submission identifiers:</xsl:text>
    <xsl:value-of select="$newline" />
    <xsl:apply-templates select="SUBMISSION" />
    <xsl:value-of select="$newline" />

    <xsl:text>- Sample identifiers:</xsl:text>
        <xsl:value-of select="$newline" />
        <xsl:value-of select="$newline" />
        <xsl:text>Accession</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:text>Alias</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:text>Status</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:text>External accession</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:text>External type</xsl:text>
        <xsl:value-of select="$newline" />
        <xsl:value-of select="$newline" />
    <xsl:apply-templates select="SAMPLE" />
    <xsl:value-of select="$newline" />

    <xsl:text>- Experiment identifiers:</xsl:text>
        <xsl:value-of select="$newline" />
        <xsl:value-of select="$newline" />
        <xsl:text>Accession</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:text>Alias</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:text>Status</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:value-of select="$newline" />
        <xsl:value-of select="$newline" />
    <xsl:apply-templates select="EXPERIMENT" />
    <xsl:value-of select="$newline" />

    <xsl:text>- Run identifiers:</xsl:text>
        <xsl:value-of select="$newline" />
        <xsl:value-of select="$newline" />
        <xsl:text>Accession</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:text>Alias</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:text>Status</xsl:text>
        <xsl:value-of select="$tab" />
        <xsl:value-of select="$newline" />
        <xsl:value-of select="$newline" />
    <xsl:apply-templates select="RUN" />
    <xsl:value-of select="$newline" />

</xsl:template>

<xsl:template match="STUDY">

  <xsl:value-of select="$newline" />
  <xsl:text>Accession: </xsl:text>
  <xsl:value-of select="@accession" />
  <xsl:value-of select="$newline" />
  
  <xsl:text>Alias: </xsl:text>  
  <xsl:value-of select="@alias" />
  <xsl:value-of select="$newline" />
  
  <xsl:text>Private until: </xsl:text>  
  <xsl:value-of select="@holdUntilDate" />
  <xsl:value-of select="$newline" />
  
  <xsl:value-of select="$newline" />
  
</xsl:template>

<xsl:template match="SUBMISSION">
  <xsl:value-of select="$newline" />
  <xsl:text>Accession: </xsl:text>
  <xsl:value-of select="@accession" />
  <xsl:value-of select="$newline" />
  
  <xsl:text>Alias: </xsl:text>
  <xsl:value-of select="@alias" />
  <xsl:value-of select="$newline" />
</xsl:template>

<xsl:template match="SAMPLE">

    <xsl:value-of select="@accession" />
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@alias" />
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@status" />
    <xsl:value-of select="$tab" />
    <xsl:value-of select="EXT_ID/@accession" />
    <xsl:value-of select="$tab" />
    <xsl:value-of select="EXT_ID/@type" />
    <xsl:value-of select="$newline" />

</xsl:template>

<xsl:template match="EXPERIMENT">

    <xsl:value-of select="@accession" />
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@alias" />
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@status" />
    <xsl:value-of select="$newline" />
    
</xsl:template>

<xsl:template match="RUN">

    <xsl:value-of select="@accession" />
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@alias" />
    <xsl:value-of select="$tab" />
    <xsl:value-of select="@status" />
    <xsl:value-of select="$newline" />

</xsl:template>

</xsl:stylesheet>
