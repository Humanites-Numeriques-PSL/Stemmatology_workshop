<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="#all"
  expand-text="yes"
  version="3.0">
  
  <xsl:output method="xml" indent="yes"/>
  
  
  <xsl:template match="/">
    <xsl:variable name="doc">
        <xsl:apply-templates select="@* | node()" mode="reorderVarSeqs"/>
    </xsl:variable>
    
    <xsl:message>First pass result: <xsl:copy-of select="$doc"/></xsl:message>
    
    
    <xsl:apply-templates select="$doc/node()" mode="transform"/>
    
  </xsl:template>
  
  
  <xsl:template match="node() | @*" mode="#all">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  
  <xsl:template match="tei:app[tei:rdg[@varSeq]]" mode="reorderVarSeqs">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates select="tei:lem" mode="#current"></xsl:apply-templates>
      <xsl:for-each-group select="tei:rdg" group-by="@varSeq">
        <xsl:sort select="@varSeq" order="ascending"/>
        <xsl:apply-templates select="." mode="#current"/>
      </xsl:for-each-group>
      <xsl:apply-templates select="element()[not(local-name() = 'rdg' or local-name() = 'lem')]" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  
  
  <xsl:template match="tei:text" mode="transform">
    <xsl:copy>
      <interpGrp type="intrinsic">
        <interp xml:id="RatingA">
          <p>The current reading is absolutely more likely than the linked reading.</p>
          <certainty locus="value" degree="100"/>
        </interp>
        <interp xml:id="RatingB">
          <p>The current reading is strongly more likely than the linked reading.</p>
          <certainty locus="value" degree="31.622776601683793"/>
        </interp>
        <interp xml:id="RatingC">
          <p>The current reading is more likely than the linked reading.</p>
          <certainty locus="value" degree="10"/>
        </interp>
        <interp xml:id="RatingD">
          <p>The current reading is slightly more likely than the linked reading.</p>
          <certainty locus="value" degree="3.1622776601683795"/>
        </interp>
        <interp xml:id="EqualRating">
          <p>The current reading and the linked reading are equally likely.</p>
          <certainty locus="value" degree="1"/>
        </interp>
      </interpGrp>
      <!-- TODO: add transcriptional, in case of complex substitution model. For now, we'll use the types -->
      <interpGrp type="transcriptional">
        <interp xml:id="lexsemstrong">
          <p>Strong lexical and semantic variation.</p>
        </interp>
        <interp xml:id="lexsemweak">
          <p></p>
        </interp>
        <interp xml:id="lexsemnonsense">
          <p></p>
        </interp>
        <interp xml:id="order">
          <p></p>
        </interp>
        <interp xml:id="absence">
          <p></p>
        </interp>
        <!-- Omitted from analysis -->
        <!--<interp xml:id="morphosyntactic">
          <p>.</p>
        </interp>
        <interp xml:id="morphologic">
          <p>.</p>
        </interp>
        <interp xml:id="graphemic">
          <p>.</p>
        </interp>-->
      </interpGrp>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  
  
  <xsl:template match="tei:app[(not(tei:lem) and not(tei:rdg[@varSeq])) or @type = ('graphemic', 'morphologic', 'morphosyntactic') ]" mode="transform"/>
  
  <xsl:template match="tei:app" mode="transform">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
      <xsl:if test="( count(tei:rdg) + count(tei:lem) ) > 1">
        <note>
          <listRelation type="intrinsic">
            <!-- First, case if there are no @varseq -->
            <xsl:for-each select="tei:lem | tei:rdg">
              <xsl:if test="following-sibling::tei:lem | following-sibling::tei:rdg">
                <xsl:variable name="current" select="count(preceding-sibling::tei:rdg)
                  + count(preceding-sibling::tei:lem) + 1"/>
                <xsl:element name="relation">
                  <xsl:attribute name="active" select="$current"/>
                  <xsl:attribute name="passive" select="$current+1"/>
                  <xsl:attribute name="ana">
                    <xsl:choose>
                      <xsl:when test="./local-name() ='lem'">
                        <xsl:choose>
                          <xsl:when test="@cert = 'high'"><xsl:text>#RatingA</xsl:text></xsl:when>
                          <xsl:when test="@cert = 'medium'"><xsl:text>#RatingB</xsl:text></xsl:when>
                          <xsl:when test="@cert = 'low'"><xsl:text>#RatingC</xsl:text></xsl:when>
                          <xsl:otherwise><xsl:text>#RatingD</xsl:text></xsl:otherwise>
                        </xsl:choose>
                      </xsl:when>
                      <xsl:otherwise><!-- second case, not a lem -->
                        <xsl:choose>
                          <xsl:when test="@varSeq">
                            <xsl:choose>
                              <!-- First possibility, lower varSeq -->
                              <xsl:when test="@varSeq &lt; following-sibling::tei:rdg[1]/@varSeq">
                                <!-- Then, let's take the @cert into account -->
                                <xsl:choose>
                                  <xsl:when test="@cert = 'high'"><xsl:text>#RatingA</xsl:text></xsl:when>
                                  <xsl:when test="@cert = 'medium'"><xsl:text>#RatingB</xsl:text></xsl:when>
                                  <xsl:when test="@cert = 'low'"><xsl:text>#RatingC</xsl:text></xsl:when>
                                  <xsl:otherwise><xsl:text>#RatingD</xsl:text></xsl:otherwise>
                                </xsl:choose>
                                <!-- otherwise, equal rating -->
                              </xsl:when>
                              <xsl:otherwise><xsl:text>#EqualRating</xsl:text></xsl:otherwise>
                            </xsl:choose>
                            </xsl:when>
                          <xsl:otherwise><xsl:text>#EqualRating</xsl:text></xsl:otherwise>
                        </xsl:choose>
                      </xsl:otherwise>
                    </xsl:choose>
                    <!-- And now add the transcriptional values -->
                    <xsl:if test="parent::tei:app/@type">
                      <xsl:text> #</xsl:text>
                      <xsl:value-of select="translate(parent::tei:app/@type, ':', '')"/>
                    </xsl:if>
                  </xsl:attribute>
                </xsl:element>
              </xsl:if>
            </xsl:for-each>
          </listRelation>
        </note>
      </xsl:if>
    </xsl:copy>
    
    
    
    
  </xsl:template>
  
  
  <xsl:template match="tei:lem | tei:rdg" mode="transform">
    <xsl:element name="rdg">
      <xsl:attribute name="n">
        <xsl:value-of select="count(preceding-sibling::tei:rdg)
          + count(preceding-sibling::tei:lem) + 1
          "/>
      </xsl:attribute>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  
  <xsl:template match="@type" mode="transform">
    <xsl:copy-of select="."/>
    <xsl:attribute name="ana">
      <xsl:text>#</xsl:text>
      <xsl:value-of select="translate(., ':', '')"/>
    </xsl:attribute>
    
  </xsl:template>
  
  
  
</xsl:stylesheet>
