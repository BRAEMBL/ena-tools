<?xml version="1.0"?>
<xsl:stylesheet 
  version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
>
<!--

  This stylesheet is used to ...

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

<xsl:template match="CHECKLIST_ATTRIBUTE">

<xsl:if test="count(UNITS) &gt; 0">

    <xsl:value-of select="TAG" />
    <xsl:value-of select="$tab" />
    <xsl:apply-templates select="UNITS" />
    <xsl:value-of select="$newline" />

</xsl:if> 

</xsl:template>

<xsl:template match="UNITS">
  <xsl:for-each select="UNIT">
      <xsl:value-of select="text()" />
      <xsl:value-of select="$tab" />
  </xsl:for-each>
</xsl:template>

<!-- Prevent other nodes printed out as text. -->
<xsl:template match="text()|@*">
</xsl:template>

</xsl:stylesheet>
