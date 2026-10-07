---
title: "Agent Resource Discovery (ARD): Initial Contact"
abbrev: "ARD Initial Contact"
category: std

docname: draft-jimenez-ard-initial-contact-latest
submissiontype: IETF
ipr: trust200902
v: 3
area: "Applications and Real-Time"
keyword:
 - agent discovery
 - well-known URI
 - SVCB
 - DNS-SD
 - mDNS
 - DAWN
venue:
  group: "Discovery of Agents With Names (DAWN)"
  type: "Proposed Working Group"
  mail: "dawn@ietf.org"
  arch: "https://mailarchive.ietf.org/arch/browse/dawn/"
  github: "jaimejim/-ietf-draft-ard-initial-contact"
  latest: "https://jaimejim.github.io/-ietf-draft-ard-initial-contact/draft-jimenez-ard-initial-contact.html"

author:
 -
    fullname: Jaime Jiménez
    organization: Ericsson
    email: jaime.jimenez@ericsson.com

normative:
  RFC1035:
  RFC3986:
  RFC6335:
  RFC6690:
  RFC6762:
  RFC6763:
  RFC8288:
  RFC8552:
  RFC8615:
  RFC9110:
  RFC9460:
  I-D.mk-dnsop-svcb-well-known:
  ARD:
    title: "Agent Resource Discovery (ARD)"
    author:
      - name: Junjie Bu
      - name: R.V. Guha
      - name: Jaime Jiménez
    date: 2026-10
    target: https://mindpower.github.io/ietf-draft-agent-resources-discovery/draft-bu-agent-resources-discovery.html
    seriesinfo:
      Internet-Draft: draft-bu-agent-resources-discovery

informative:
  RFC4033:
  RFC7252:
  RFC8126:
  RFC8766:
  RFC8801:
  RFC8910:
  RFC9176:
  RFC9461:
  RFC9462:
  RFC9499:
  RFC9727:
  I-D.ietf-core-groupcomm-bis:
  I-D.mozleywilliams-dnsop-dnsaid:
  I-D.nemethi-dawn-aid:
  I-D.seethiraju-dawn-dan:
  I-D.jakab-dawn-agent-discovery-mdns:
  I-D.jimenez-dawn-discovery-landscape:
  I-D.farrel-dawn-terminology:
  I-D.king-dawn-requirements:
  I-D.cui-dawn-mdi-model:
  AGENT-DIRECTORY:
    title: "Agent Directory (AD)"
    author:
      - name: Jaime Jiménez
    date: 2026-05
    target: https://datatracker.ietf.org/doc/draft-jimenez-ad-agent-directory/
    seriesinfo:
      Internet-Draft: draft-jimenez-ad-agent-directory-01
  DAWN-CHARTER:
    title: "Discovery of Agents With Names (DAWN) - Proposed Charter"
    author:
      - org: IETF
    date: 2026
    target: https://datatracker.ietf.org/doc/charter-ietf-dawn/
  A2A:
    title: "Agent2Agent (A2A) Protocol Specification"
    author:
      - org: Linux Foundation
    date: 2025
    target: https://a2a-protocol.org/latest/specification/
  MCP:
    title: "Model Context Protocol Specification"
    author:
      - org: Anthropic
    date: 2025
    target: https://modelcontextprotocol.io/specification/

--- abstract

This document specifies how a client finds an entry point to Agent Resource Discovery (ARD): the URI of an ARD catalog from which agent resources can be enumerated and looked up. It defines the use of a well-known URI, an HTTP link relation, DNS Service Binding (SVCB and HTTPS) records, DNS-Based Service Discovery (DNS-SD) over unicast and Multicast DNS, and the CoRE Link Format for constrained networks. The mechanisms share one output, a set of entry point URIs with minimal metadata, and one trust rule: everything learned during initial contact is a hint that the client verifies when it retrieves the catalog from its origin. The catalog format and the lookup interface are specified in the companion ARD documents.

--- middle

# Introduction {#intro}

{{ARD}} defines a catalog of agent resources: a document, served over HTTPS, in which a publisher lists the agents, tool servers, and skills it offers, each entry pointing at the artifact that describes the resource in its native protocol, such as an Agent Card {{A2A}} or an MCP server description {{MCP}}. ARD also defines a lookup interface over that catalog. Both assume that the client already holds the URI of the catalog.

Obtaining that URI is a separate problem. A client that knows an organization's domain name, or that has joined a local network, has no catalog URI yet. It can guess a well-known path, consult the DNS, listen on the local link, or follow a link from a web page. Each of these steps exists already in an IETF specification written for another purpose: well-known URIs {{RFC8615}}, web linking {{RFC8288}}, Service Binding records {{RFC9460}}, DNS-SD {{RFC6763}} with Multicast DNS {{RFC6762}}, and the CoRE Link Format {{RFC6690}}. What is missing is the binding of each to ARD: which names to query, which parameters to publish, and what the client may conclude from an answer. The same gap exists for the CoRE Resource Directory, and {{Section 4.1 of RFC9176}} closes it with a list of configured, network-provided, and heuristic ways of finding the directory.

The DAWN charter {{DAWN-CHARTER}} names this step "initial discovery": a client obtaining the minimum public information about an AI resource, where the resource may be "a service such as a catalog that will further the discovery process". The charter lists the deployment contexts a mechanism has to cover: the local network, an organization's own infrastructure, and cooperating parties over the public Internet. The mechanisms in this document map onto those three contexts.

This document specifies initial contact for ARD: how a client obtains one or more ARD entry points and what it knows about each when it has them. It does not specify the catalog representation, the lookup or search interfaces, or how publishers register entries; those are the subjects of {{ARD}} and {{AGENT-DIRECTORY}}. It does not define new DNS resource record types, new SvcParamKeys, or new transport protocols.

# Conventions and Definitions {#definitions}

{::boilerplate bcp14-tagged}

This document uses the DNS terminology of {{RFC9499}}, the DNS-SD terms "service type", "service instance", "browse", and "resolve" from {{RFC6763}}, and the terms "origin" and "authoritative" as defined for HTTP in {{Sections 4.3.1 and 4.3.3 of RFC9110}}.

{:vspace}
ARD catalog:
: A document listing agent resources in the format defined in {{ARD}}. A catalog has an origin; its entries may point at resources hosted elsewhere.

Entry point:
: A URI from which an ARD catalog can be retrieved, together with the metadata about it that a client learned during initial contact ({{entry-point}}).

Publisher:
: The party that controls a domain name and publishes a catalog of agent resources under it.

Client:
: Software that needs an ARD entry point. The client is often itself an agent acting for a user or for another agent.

Initial contact:
: The process by which a client obtains one or more entry points, starting from a domain name, a local network attachment, or configuration.

Hint:
: Information about an entry point obtained from a source other than the entry point's own origin. DNS answers, multicast responses, and links found in third-party documents are hints.

# The Entry Point {#entry-point}

Every mechanism in this document produces the same thing: zero or more entry points. An entry point has one mandatory element and two optional ones.

{:vspace}
URI:
: The URI of the catalog. The mechanisms in this document produce "https" URIs {{RFC9110}}. A DNS-SD or SVCB answer may carry protocol identifiers for other schemes; this document does not specify how a client uses them.

Media type:
: The media type the client can expect when it retrieves the URI. When a mechanism carries no media type, the client assumes the ARD catalog media type defined in {{ARD}}.

Source:
: The mechanism that produced the entry point and, where applicable, the DNS name or network interface it came from. The client keeps the source so that it can rank candidates and so that a failing entry point can be attributed to a source for rate limiting ({{procedure}}).

An entry point is a hint until the client has retrieved the catalog from the URI and authenticated the origin as described in {{security}}. Nothing in a DNS answer or a multicast response makes a catalog authoritative for a publisher; the catalog's own content and signatures do, as specified in {{ARD}}.

A domain may publish more than one catalog, for instance one per business unit or one per protocol family. Each mechanism below can return several entry points, and the client treats them as a set. A catalog may in turn link to further catalogs; following those links is part of lookup, not of initial contact.

# Discovery Mechanisms {#mechanisms}

The mechanisms are grouped by where the client starts: from configuration ({{static}}), from a domain name over HTTP ({{http-mechanisms}}), from a domain name over the DNS ({{dns-mechanisms}}), or from a network attachment with no domain name at all ({{local-mechanisms}}). {{procedure}} specifies the order in which a client tries them.

## Configured Entry Points {#static}

A client MAY be configured with one or more entry points directly. Configuration covers the cases that {{Section 4.1 of RFC9176}} lists for a Resource Directory: a URI set by an operator, by a device profile, or by the application that ships the client. A configured entry point carries the source "configuration" and is tried before any discovered one.

Configuration is also how a client learns about catalogs that are not discoverable by design, for example a private catalog reachable only inside an organization. Nothing in this document requires a publisher to make a catalog discoverable.

## HTTP-Based Mechanisms {#http-mechanisms}

Both mechanisms in this section start from an "https" origin, which the client has formed from a domain name it already knows. They require no DNS records beyond those the origin needs anyway.

### Well-Known URI {#well-known}

A publisher that hosts a catalog at its origin MAY make it available at the well-known URI {{RFC8615}} with the suffix "ard.json":

~~~
https://example.com/.well-known/ard.json
~~~

A GET request to this URI returns an ARD catalog, or a redirect to one. A publisher MAY redirect to a catalog on another host; the client follows redirects as in {{Section 15.4 of RFC9110}} and records the final URI as the entry point. The redirect target becomes the catalog's origin for the purposes of {{security}}.

A client that holds only a domain name forms the well-known URI with that name as the authority and the default "https" port. The scope of a well-known URI is its origin: a catalog at "https://example.com/.well-known/ard.json" says nothing about "https://agents.example.com/". A publisher that spreads catalogs over several hosts either serves one catalog at the apex that links to the others, or publishes DNS records as in {{dns-mechanisms}}.

This document requests the registration of the suffix in {{iana-well-known}}. {{ARD}} defines the representation returned.

### Link Relation {#link-relation}

A publisher MAY point to a catalog from any HTTP resource with the "ard" link relation {{RFC8288}}. The link context is the resource that carries the link; the link target is an ARD catalog. The relation is used in a Link header field:

~~~
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Link: <https://agents.example.com/catalog>; rel="ard";
      type="application/ard+json"
~~~

and in HTML:

~~~
<link rel="ard" type="application/ard+json"
      href="https://agents.example.com/catalog">
~~~

A client that has retrieved any representation from a publisher's origin, including a response to the well-known URI that is not itself a catalog, examines the Link header field and, for HTML content, the link elements in the document head. A publisher SHOULD answer a HEAD request to its origin's root resource with a Link header field carrying the relation, following the pattern of {{Section 2 of RFC9727}}, so that a client can find the catalog without parsing a document body.

Links found in a document from the publisher's own origin have the origin as their source. Links found in third-party documents are hints from that third party.

This document requests the registration of the relation in {{iana-link-relation}}.

## DNS-Based Mechanisms {#dns-mechanisms}

The DNS lets a publisher advertise an entry point before the client opens a connection, and lets it place the catalog on a host other than the domain apex. Three record types apply: HTTPS records at the origin name, SVCB records under an underscored label, and DNS-SD records under the service type defined here. A publisher chooses by where the catalog is hosted; a client queries all three in the order given in {{procedure}}.

### HTTPS Record with the "well-known" Key {#https-rr}

A publisher whose catalog is served at the origin of a domain name MAY advertise it in the HTTPS record {{RFC9460}} of that name using the "well-known" SvcParamKey {{I-D.mk-dnsop-svcb-well-known}}:

~~~
example.com. 3600 IN HTTPS 1 . (
    alpn="h2,h3"
    well-known="ard.json"
)
~~~

The client forms the entry point by appending "/.well-known/" and the suffix to the origin, as specified in {{Section 4 of I-D.mk-dnsop-svcb-well-known}}. The HTTPS record changes connection parameters, not the origin: the certificate is validated for "example.com" ({{Section 9 of RFC9460}}). A client that already resolves HTTPS records when connecting to an origin learns the entry point at no extra cost.

The "well-known" key MAY list other suffixes alongside "ard.json", for instance "api-catalog" {{RFC9727}} or "agent-card.json" {{A2A}}. The client selects the suffixes it understands.

### SVCB Record under the "_ard" Label {#svcb-rr}

A publisher whose catalog is hosted on a different host than the domain apex, or by a service provider, MAY publish an SVCB record under the "_ard" label of its domain. The label follows the Attrleaf naming pattern {{RFC8552}} required by {{Section 2.3 of RFC9460}}; this document requests its registration in {{iana-attrleaf}}.

~~~
_ard.example.com. 3600 IN SVCB 1 catalog.example.net. (
    alpn="h2"
    well-known="ard.json"
)
~~~

This document is the protocol mapping for the "_ard" label in the sense of {{Section 2.4.3 of RFC9460}}:

* The scheme of the entry point is "https".
* The authority is the TargetName, or the owner name without the "_ard" label when the TargetName is ".", with the port from the "port" key or 443. This is the rule of {{Section 4 of I-D.mk-dnsop-svcb-well-known}} for SVCB records.
* The path is "/.well-known/" followed by a suffix from the "well-known" key. A record without a "well-known" key denotes the suffix "ard.json".
* The "alpn", "port", "ipv4hint", "ipv6hint", "ech", and "well-known" keys are applicable. The "mandatory" key is processed as in {{Section 8 of RFC9460}}. Other keys are ignored.
* AliasMode records are followed as in {{Section 2.4.2 of RFC9460}}.

In the example, the entry point is "https://catalog.example.net/.well-known/ard.json". The TLS certificate is validated for "catalog.example.net", the host named in the URI. The client records "_ard.example.com" as the source so that it can later check that the catalog claims to publish for "example.com" ({{sec-hints}}).

Underscored owner names cannot appear in publicly issued certificates, so the TargetName is what the client connects to and authenticates. A publisher MUST NOT use "." as the TargetName unless the apex name itself serves the catalog; in that case the HTTPS record of {{https-rr}} is the shorter route.

An RRset MAY carry several ServiceMode records with different TargetNames or different suffixes. Each yields one entry point; SvcPriority orders them.

### DNS-SD Service Type "_ard._tcp" {#dns-sd}

A publisher MAY advertise catalogs as DNS-SD service instances {{RFC6763}} of the service type "_ard._tcp". DNS-SD suits two cases that the SVCB record does not cover well: a domain with several catalogs that an administrator wants to name and enumerate, and networks that already run DNS-SD, with or without Multicast DNS ({{mdns}}).

A client browses by querying PTR records at `_ard._tcp.<domain>`, then resolves each service instance name to its SRV and TXT records:

~~~
_ard._tcp.example.com. 3600 IN PTR Travel._ard._tcp.example.com.
_ard._tcp.example.com. 3600 IN PTR Devtools._ard._tcp.example.com.

Travel._ard._tcp.example.com. 3600 IN SRV 0 0 443 catalog.example.net.
Travel._ard._tcp.example.com. 3600 IN TXT (
    "txtvers=1"
    "path=/.well-known/ard.json"
    "type=application/ard+json"
)
~~~

The TXT record carries the following keys, with the syntax of {{Section 6 of RFC6763}}:

{:vspace}
txtvers:
: The version of this key set. This document defines version 1. A client ignores records with a version it does not understand.

path:
: The path and optional query component of the entry point, as an absolute path {{RFC3986}}. Absent, the path is "/.well-known/ard.json". This follows the convention established for "_http._tcp" in {{Section 6.4 of RFC6763}}.

type:
: The media type of the catalog. Absent, the client assumes the ARD catalog media type.

The entry point is "https://" followed by the SRV target, the SRV port when it is not 443, and the path. The service name "ard" is requested in {{iana-service-name}}. The scheme is always "https"; this document defines no "_ard._udp" service.

A client that knows a domain but wants to learn which DNS-SD domains the publisher recommends for browsing MAY first query the domain enumeration names of {{Section 11 of RFC6763}}, `b._dns-sd._udp.<domain>` and `lb._dns-sd._udp.<domain>`.

## Local Network Mechanisms {#local-mechanisms}

A client attached to a network it knows nothing about has no domain name to start from. Two existing mechanisms fit: Multicast DNS for IP networks that carry link-local multicast, and CoRE multicast discovery for constrained networks that already speak CoAP.

### Multicast DNS {#mdns}

On the local link, the client browses for "_ard._tcp.local." over Multicast DNS {{RFC6762}}, with the same PTR, SRV, and TXT records as in {{dns-sd}}. A catalog host that wishes to be found on the link answers for its service instance. The TXT keys are unchanged.

Names under "local." do not appear in publicly issued certificates, so a client cannot authenticate the catalog origin by the usual rule. A publisher that advertises over Multicast DNS SHOULD set the SRV target to a unicast DNS name for which it holds a certificate, so that the entry point URI carries an authenticable host, and MAY additionally publish an address record for the ".local" name. Where a Discovery Proxy {{RFC8766}} is deployed, the link-local advertisements appear in the unicast DNS-SD namespace and the client can use {{dns-sd}} instead.

Entry points learned over Multicast DNS carry the network interface as their source. {{sec-local}} describes what the client may conclude from them.

Multicast DNS discovers catalogs, not individual agents. {{I-D.jakab-dawn-agent-discovery-mdns}} describes browsing for agents themselves under "_agent._tcp"; the two service types coexist, and a catalog found through "_ard._tcp" may list the same agents that answer under "_agent._tcp".

### CoRE Link Format and Multicast CoAP {#core}

In constrained networks {{RFC7252}}, hosts describe their resources in the CoRE Link Format {{RFC6690}} at "/.well-known/core", and a client finds hosts by sending a multicast GET to the "All CoAP Nodes" address ({{Section 8 of RFC7252}}). A host that serves or knows an ARD catalog MAY list the entry point there with the resource type "ard":

~~~ coap
GET coap://[ff02::fd]/.well-known/core?rt=ard (NON)

2.05 Content
Content-Format: 40 (application/link-format)

<https://catalog.example.net/.well-known/ard.json>;rt="ard";
    type="application/ard+json"
~~~

The link target is an absolute "https" URI; the CoAP host is only the place where the link was found, and the entry point's source. The same link MAY be served at "/.well-known/core" over HTTP by hosts that support it ({{Section 4 of RFC6690}}). Multicast requests follow {{I-D.ietf-core-groupcomm-bis}}: they are Non-confirmable, responses are spread over the leisure period, and the client rate-limits repeated queries. {{Section 4.1 of RFC9176}} contains the corresponding procedure for finding a Resource Directory and advises against multicast discovery in mesh networks; the same advice applies here.

The resource type value is requested in {{iana-rt}}.

# Client Procedure {#procedure}

A client collects entry points from every mechanism it can use, orders them by source, and treats a failure of one entry point as a reason to rate-limit further attempts against the source that produced it. The ordered procedure is specified with the mechanisms.

# Security Considerations {#security}

Initial contact runs before any authenticated relationship exists between the client and the publisher. Every mechanism in this document hands the client a hint, and an attacker who controls the channel can hand it a wrong one. The client retrieves the catalog from the URI, authenticates the origin as in {{Section 4.3.3 of RFC9110}}, and applies the publisher checks of {{ARD}} to the content before it relies on anything it found.

## Hints and Authority {#sec-hints}

A DNS answer or a multicast response names a host; TLS authenticates that host, not the publisher the client was looking for. The binding between a catalog and a publisher's domain is established by the catalog content as specified in {{ARD}}, never by the mechanism that found it.

## Local Network Discovery {#sec-local}

Any host on the link can answer a multicast query. Entry points learned this way are the least trusted source and are verified like any other.

# Privacy Considerations {#privacy}

Queries for a publisher's entry point reveal the client's interest in that publisher to the resolver and to observers on the path; multicast queries reveal it to the whole link.

# IANA Considerations {#iana}

This document requests a well-known URI suffix ({{iana-well-known}}), a link relation ({{iana-link-relation}}), an underscored DNS node name ({{iana-attrleaf}}), a DNS-SD service name ({{iana-service-name}}), and a CoRE resource type ({{iana-rt}}).

## Well-Known URI {#iana-well-known}

The suffix "ard.json" in the "Well-Known URIs" registry {{RFC8615}}.

## Link Relation {#iana-link-relation}

The relation "ard" in the "Link Relations" registry {{RFC8288}}.

## Underscored and Globally Scoped DNS Node Name {#iana-attrleaf}

The node name "_ard" for the SVCB RR type in the registry defined by {{RFC8552}}.

## Service Name {#iana-service-name}

The service name "ard" over TCP, without a port, in the registry defined by {{RFC6335}}.

## Resource Type Link Target Attribute Value {#iana-rt}

The value "ard" in the CoRE Parameters registry defined by {{RFC6690}}.

--- back

# Acknowledgments
{:numbered="false"}

The split of the ARD work into initial contact, lookup, and registration documents was proposed by Jari Arkko. Junjie Bu and R.V. Guha wrote the ARD specification this document attaches to. Wes Hardaker and Sam Sharaf took part in the discussions that shaped the scope. Jim Mozley and Daniel King's work on the "well-known" SvcParamKey provided the DNS binding used here.
