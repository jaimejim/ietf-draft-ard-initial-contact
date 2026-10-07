---
title: "Agent Resource Discovery (ARD): Initial Contact"
abbrev: "ARD Initial Contact"
category: std

docname: draft-jimenez-ard-initial-contact-latest
submissiontype: IETF
ipr: trust200902
v: 3
area: "Internet"
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
 -
    fullname: Junjie Bu
    organization: Google
    email: jbu@google.com
 -
    fullname: Jari Arkko
    organization: Ericsson
    email: jari.arkko@ericsson.com

normative:
  RFC3986:
  RFC4033:
  RFC6335:
  RFC6762:
  RFC6763:
  RFC8288:
  RFC8615:
  RFC9110:
  RFC9111:
  RFC9460:

informative:
  RFC1035:
  RFC9457:
  I-D.mozleywilliams-dnsop-dnsaid:
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
  RFC2132:
  RFC3646:
  RFC8106:
  RFC8552:
  RFC8766:
  RFC9176:
  RFC9264:
  RFC9461:
  RFC9462:
  RFC9499:
  RFC9727:
  I-D.mk-dnsop-svcb-well-known:
  I-D.nemethi-dawn-aid:
  I-D.seethiraju-dawn-dan:
  I-D.jakab-dawn-agent-discovery-mdns:
  I-D.morrison-mcp-dns-discovery:
  I-D.zahed-acap:
  I-D.pro-adp-agent-discovery:
  I-D.besleaga-agentic-knowledge-wellknown:
  I-D.jimenez-dawn-discovery-landscape:
  I-D.farrel-dawn-terminology:
  I-D.king-dawn-requirements:
  I-D.cui-dawn-mdi-model:
  I-D.jimenez-agent-directory:
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

This document specifies how a client finds an entry point to Agent Resource Discovery (ARD): the URI of an ARD catalog from which agent resources can be enumerated and looked up. It defines a well-known URI, an HTTP link relation, the use of DNS Service Binding records at the organization index name defined by DNS for AI Discovery, and a DNS-Based Service Discovery (DNS-SD) service type usable over unicast DNS and Multicast DNS. The mechanisms share one output, a set of catalog URIs with their sources, and one trust rule: everything learned during initial contact is a hint that the client verifies when it retrieves the catalog from its origin. The catalog format, the lookup interface, and the binding of a catalog to its publisher are specified in the companion ARD documents.

--- middle

# Introduction {#intro}

{{ARD}} defines a catalog of agent resources: a document, served over HTTPS, in which a publisher lists the agents, tool servers, and skills it offers, each entry pointing at the artifact that describes the resource in its native protocol, such as an Agent Card {{A2A}} or an MCP server description {{MCP}}. ARD also defines a lookup interface over that catalog. Both assume that the client already holds the URI of the catalog.

Obtaining that URI is a separate problem. A client that knows an organization's domain name, or that has joined a local network, has no catalog URI yet. It can request a well-known path, consult the DNS, browse the local link, or follow a link from a web resource. Each of these steps exists already in an IETF specification written for another purpose: well-known URIs {{RFC8615}}, web linking {{RFC8288}}, Service Binding records {{RFC9460}}, and DNS-SD {{RFC6763}} with Multicast DNS {{RFC6762}}. What is missing is the binding of each to ARD: which names to query, which parameters to publish, and what the client may conclude from an answer. The same gap exists for the CoRE Resource Directory, and {{Section 4.1 of RFC9176}} closes it with a list of configured, network-provided, and heuristic ways of finding the directory.

The DAWN charter {{DAWN-CHARTER}} calls this step "initial discovery": a client obtaining the minimum public information about an AI resource, where the resource may be "a service such as a catalog that will further the discovery process". This document uses the term initial contact for the same step. The charter lists the deployment contexts a mechanism has to cover: the local network, an organization's own infrastructure, and discovery between organizations over the public Internet, with or without a prior relationship between them. The mechanisms in this document map onto those three contexts.

This document specifies initial contact for ARD: how a client obtains one or more ARD catalog URIs and what it knows about each when it has them. The output is always a catalog. It does not specify the catalog representation, the lookup or search interfaces, how publishers register entries, or how a catalog is bound to the publisher it speaks for; those are the subjects of {{ARD}} and {{I-D.jimenez-agent-directory}}. It produces "https" URIs only, and it does not define new DNS resource record types, new SvcParamKeys, or new transport protocols.

# Conventions and Definitions {#definitions}

{::boilerplate bcp14-tagged}

This document uses the DNS terminology of {{RFC9499}}, the DNS-SD terms "service type", "service instance", "browse", and "resolve" from {{RFC6763}}, and the terms "origin" and "authoritative" as defined for HTTP in {{Sections 4.3.1 and 4.3.3 of RFC9110}}.

{:vspace}
ARD catalog:
: A document listing agent resources in the format defined in {{ARD}}. A catalog has an origin; its entries may point at resources hosted elsewhere.

Entry point:
: The URI of an ARD catalog, together with the source from which the client learned it ({{entry-point}}).

Publisher:
: The party that controls a domain name and publishes a catalog of agent resources under it.

Client:
: Software that needs an ARD entry point. The client is often itself an agent acting for a user or for another agent.

Initial contact:
: The process by which a client obtains one or more entry points, starting from a domain name, a local network attachment, or configuration.

Hint:
: Information about an entry point obtained from a source other than the entry point's own origin. DNS answers, multicast responses, and links found in third-party documents are hints.

# The Entry Point {#entry-point}

Every mechanism in this document produces the same thing: zero or more entry points. An entry point has two elements.

{:vspace}
URI:
: The "https" URI {{RFC9110}} of the catalog. Retrieving it returns an ARD catalog in a representation defined by {{ARD}}; a client that can handle several representations selects among them with content negotiation.

Source:
: The mechanism that produced the entry point and, where applicable, the DNS name or network interface it came from. The client keeps the source so that it can rank candidates ({{procedure}}), attribute a failing entry point to a source for rate limiting, and let local policy decide what to accept.

The two elements are a subset of the minimum discoverable information that DAWN is defining {{I-D.cui-dawn-mdi-model}}: the URI is an endpoint locator, and the source is provenance of the discovery information rather than of the entity. The terminology of {{I-D.farrel-dawn-terminology}} and the requirements of {{I-D.king-dawn-requirements}} apply to this document as to other DAWN work; in particular, the well-known URI of {{well-known}} is the predictable entry point that REQ-PROTO-4 of that document asks for.

An entry point is a hint until the client has retrieved the catalog from the URI and authenticated the origin as described in {{security}}. Nothing in a DNS answer or a multicast response makes a catalog authoritative for a publisher. Which publisher a catalog speaks for is established by the catalog's own content, as specified in {{ARD}}, and is outside this document.

A domain may publish more than one catalog, for instance one per business unit or one per protocol family. Each mechanism below can return several entry points, and the client treats them as a set. A catalog may in turn link to further catalogs; following those links is part of lookup, not of initial contact.

# Discovery Mechanisms {#mechanisms}

The mechanisms are grouped by where the client starts: from configuration ({{static}}), from a domain name over HTTP ({{http-mechanisms}}), from a domain name over the DNS ({{dns-mechanisms}}), or from a network attachment with no domain name at all ({{local-mechanisms}}). {{procedure}} specifies how a client combines them.

The well-known URI of {{well-known}} is the mandatory baseline. A publisher that wants its catalog to be discoverable MUST serve it there, directly or through one redirect, and every client MUST implement the well-known fetch. The other mechanisms are optional for publishers; they add DNS pre-resolution, off-apex hosting, named enumeration, and local-network discovery on top of the baseline. A client that claims to discover catalogs on the local network MUST implement the Multicast DNS browse of {{mdns}}.

## Configured Entry Points {#static}

A client MAY be configured with one or more entry points directly. Configuration covers the cases that {{Section 4.1 of RFC9176}} lists for a Resource Directory: a URI set by an operator, by a device profile, or by the application that ships the client. A configured entry point carries the source "configuration" and is tried before any discovered one.

Configuration is also how a client learns about catalogs that are not discoverable by design, for example a private catalog reachable only inside an organization. Nothing in this document requires a publisher to make a catalog discoverable.

## HTTP-Based Mechanisms {#http-mechanisms}

Both mechanisms in this section start from an "https" origin, which the client has formed from a domain name it already knows. They require no DNS records beyond those the origin needs anyway.

### Well-Known URI {#well-known}

A publisher makes its catalog available at the well-known URI {{RFC8615}} with the suffix "ard":

~~~
https://example.com/.well-known/ard
~~~

A GET request to this URI returns an ARD catalog, or a redirect to one. A publisher whose catalog is hosted on another host, for instance at a service provider, serves a redirect at this URI; the client follows one redirect as in {{Section 15.4 of RFC9110}} and records the final URI as the entry point. A response that is neither a catalog nor a redirect, or a redirect that leads to another redirect, means there is no entry point at this origin ({{depth}}). A server that hosts no catalog answers 404 (Not Found) and MAY describe the condition with Problem Details {{RFC9457}}; the client needs no body to reach its conclusion.

Responses to the well-known URI, including redirects, are cacheable under the ordinary rules of {{RFC9111}}. A client stores them and does not request the URI again while the stored response is fresh; a publisher sets the freshness lifetime to the rate at which it expects the catalog location to change.

A client that holds only a domain name forms the well-known URI with that name as the authority and the default "https" port. The scope of a well-known URI is its origin: a catalog at "https://example.com/.well-known/ard" says nothing about "https://agents.example.com/". A publisher that spreads catalogs over several hosts serves one catalog at the apex that links to the others, or enumerates them with DNS-SD as in {{dns-sd}}.

This document requests the registration of the suffix in {{iana-well-known}}. {{ARD}} defines the representation returned.

### Link Relation {#link-relation}

A publisher MAY point to a catalog from any HTTP resource with the "ard" link relation {{RFC8288}} in a Link header field. The link context is the resource that carries the link; the link target is an ARD catalog.

A publisher SHOULD answer a HEAD request to its origin's root resource with a Link header field carrying the relation, following the pattern of {{Section 2 of RFC9727}}, so that a client can find the catalog without retrieving a body:

~~~ http-message
HEAD / HTTP/1.1
Host: example.com

~~~

~~~ http-message
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: 1532
Link: <https://agents.example.com/catalog>; rel="ard"

~~~

A client that has retrieved any representation from a publisher's origin, by HEAD or GET, examines the Link header field for the relation.

Links found in a response from the publisher's own origin have the origin as their source. Links found in third-party documents are hints from that third party.

This document requests the registration of the relation in {{iana-link-relation}}.

## DNS-Based Mechanisms {#dns-mechanisms}

The DNS lets a publisher advertise an entry point before the client opens a connection, and lets it place the catalog on a host other than the domain apex without a redirect. Two record forms apply: a Service Binding record at the organization index name defined by DNS for AI Discovery, and DNS-SD records under the service type defined here. The HTTPS record of the domain apex can carry the same information as an optimisation.

### Organization Index Record {#index-rr}

DNS for AI Discovery {{I-D.mozleywilliams-dnsop-dnsaid}} defines the name `_index._agents.<domain>` as the place where an organization publishes a Service Binding (SVCB) record {{RFC9460}} pointing at an index of its agents. DNS-AID leaves the format of what is served at the index out of its scope. This document specifies that an ARD catalog is one such index: a client that follows the record and finds an ARD catalog at the well-known URI of the TargetName has an entry point.

~~~
_index._agents.example.com. 3600 IN SVCB 1 catalog.example.net. (
    alpn="h2"
)
~~~

Parentheses continue a record across lines in zone file presentation format ({{Section 5.1 of RFC1035}}). The client forms the entry point as follows:

* The scheme is "https".
* The authority is the TargetName, with the port from the "port" key or 443. The TargetName MUST be a host name without underscore labels, so that a publicly issued certificate can name it; the client connects to it and authenticates it. This matches the rule in {{Section 3.2 of I-D.mozleywilliams-dnsop-dnsaid}}. A record whose TargetName is "." yields no entry point, since the owner name carries underscore labels.
* The path is "/.well-known/ard". When the record carries the "well-known" SvcParamKey {{I-D.mk-dnsop-svcb-well-known}} and its value includes "ard", the client has confirmation that the catalog is there; when the key is absent, the client requests the path and learns from the response.
* The "alpn", "port", "ipv4hint", "ipv6hint", and "ech" keys are applicable with their {{RFC9460}} semantics. The "mandatory" key is processed as in {{Section 8 of RFC9460}}. Other keys are ignored.
* One AliasMode indirection is followed as in {{Section 2.4.2 of RFC9460}}; a second ends the attempt ({{depth}}).

In the example, the entry point is "https://catalog.example.net/.well-known/ard". The TLS certificate is validated for "catalog.example.net", the host named in the URI. The client records `_index._agents.example.com` as the source, so that the publisher check of {{ARD}} can later compare the catalog against "example.com".

An RRset MAY carry several ServiceMode records with different TargetNames. Each yields one entry point; SvcPriority orders them. An index TargetName may also serve other index formats; a client that finds no catalog at the well-known path treats the record as yielding no entry point.

Note to readers of this version: the use of `_index._agents` for ARD catalogs depends on the DNS-AID authors agreeing that an ARD catalog is one of the things an index TargetName may serve. If that agreement is not reached, this document will register its own label; see {{open-issues}}.

### HTTPS Record at the Apex {#https-rr}

A publisher whose catalog is served at the origin of a domain name MAY list the suffix "ard" in the "well-known" SvcParamKey {{I-D.mk-dnsop-svcb-well-known}} of the HTTPS record {{RFC9460}} of that name:

~~~
example.com. 3600 IN HTTPS 1 . (
    alpn="h2,h3"
    well-known="ard"
)
~~~

A client that already resolves HTTPS records when connecting to an origin learns from the key that the well-known fetch of {{well-known}} will succeed, and may skip other mechanisms. The HTTPS record changes connection parameters, not the origin: the certificate is validated for "example.com" ({{Section 9 of RFC9460}}). A record without the key carries no information about the catalog, and a client proceeds as if the record were absent. The key MAY list other suffixes alongside "ard", for instance "api-catalog" {{RFC9727}} or "agent-card.json" {{A2A}}.

### DNS-SD Service Type "_ard._tcp" {#dns-sd}

A publisher MAY advertise catalogs as DNS-SD service instances {{RFC6763}} of the service type "_ard._tcp". DNS-SD suits two cases that the index record does not cover: a domain with several catalogs that an administrator wants to name and enumerate, and networks that already run DNS-SD, with or without Multicast DNS ({{mdns}}).

A client browses by querying PTR records at `_ard._tcp.<domain>`, then resolves each service instance name to its SRV and TXT records:

~~~
_ard._tcp.example.com. 3600 IN PTR Travel._ard._tcp.example.com.
_ard._tcp.example.com. 3600 IN PTR Tools._ard._tcp.example.com.

Travel._ard._tcp.example.com. 3600 IN SRV 0 0 443 (
    catalog.example.net. )
Travel._ard._tcp.example.com. 3600 IN TXT (
    "txtvers=1"
    "path=/.well-known/ard"
)
~~~

The TXT record carries the following keys, with the syntax of {{Section 6 of RFC6763}}:

{:vspace}
txtvers:
: The version of this key set. This document defines version 1. A client ignores records with a version it does not understand.

path:
: The path and optional query component of the entry point, as an absolute path {{RFC3986}}. Absent, the path is "/.well-known/ard". This follows the convention established for "_http._tcp" in {{Section 6.4 of RFC6763}}.

These keys are specific to the "_ard._tcp" service type, as {{RFC6763}} permits; they do not describe agents and do not use the agent-protocol and transport keys that other DAWN proposals are aligning for agent records ({{related}}).

The entry point is "https://" followed by the SRV target, the SRV port when it is not 443, and the path. The service name "ard" is requested in {{iana-service-name}}. The scheme is always "https"; this document defines no "_ard._udp" service.

Service instance names such as "Travel" are labels for people. {{RFC6763}} allows them to change while the service stays the same, so a client does not persist an instance name as an identifier of the catalog; the entry point URI is what it keeps. The set of instance names under `_ard._tcp.<domain>` is enumerable by design: catalogs are published to be found.

A client that knows a domain but wants to learn which DNS-SD domains the publisher recommends for browsing MAY first query the domain enumeration names of {{Section 11 of RFC6763}}, `b._dns-sd._udp.<domain>` and `lb._dns-sd._udp.<domain>`.

## Local Network Mechanisms {#local-mechanisms}

A client attached to a network it knows nothing about has no domain name to start from. Two routes exist. The network may hand the client a domain name, in which case the client is back to the mechanisms above. Otherwise the client browses the local link.

### Network-Provided Domain Name {#provided-domain}

Networks routinely provide a DNS search domain together with the resolver address: the DHCPv4 Domain Name option ({{Section 3.17 of RFC2132}}), the DHCPv6 Domain Search List option {{RFC3646}}, and the DNS Search List option in IPv6 Router Advertisements {{RFC8106}}. A client that has received a domain name this way treats it as the domain D of {{procedure}} and runs the DNS-based mechanisms against it. No new DHCP or Router Advertisement option is needed, and the network operator publishes catalogs for its users the same way it would for the Internet.

A domain learned from the network is a hint from the network, and the client records it as such.

### Multicast DNS {#mdns}

On the local link, the client browses for "_ard._tcp.local." over Multicast DNS {{RFC6762}}, with the same PTR, SRV, and TXT records as in {{dns-sd}}. A catalog host that wishes to be found on the link answers for its service instance.

Names under "local." do not appear in publicly issued certificates, so a client cannot authenticate the catalog origin by the usual rule. A publisher that advertises over Multicast DNS SHOULD set the SRV target to a unicast DNS name for which it holds a certificate, so that the entry point URI carries an authenticable host, and MAY also publish an address record for the ".local" name. Where a Discovery Proxy {{RFC8766}} is deployed, the link-local advertisements appear in the unicast DNS-SD namespace and the client can use {{dns-sd}} instead.

Entry points learned over Multicast DNS carry the network interface as their source. {{sec-local}} describes what the client may conclude from them.

Multicast DNS discovers catalogs, not individual agents. {{I-D.jakab-dawn-agent-discovery-mdns}} describes browsing for agents themselves under "_agent._tcp"; the two service types coexist, a client interested in both browses for both, and a catalog found through "_ard._tcp" may list the same agents that answer under "_agent._tcp".

# Client Procedure {#procedure}

The procedure in this section is a RECOMMENDED default. Three parts of it are requirements on every client: the well-known fetch of step 4, the depth limits of {{depth}}, and the rate limiting at the end of this section. A client MAY reorder or omit the other steps under local policy.

A client that holds a domain name D, from configuration, from the user, or from the network ({{provided-domain}}), and wants the entry points of the publisher controlling D proceeds as follows. Steps that return entry points do not stop the procedure; the client collects the results and orders them by source.

1. Configured entry points for D ({{static}}) are taken first.
2. The client queries the SVCB record for `_index._agents.D` ({{index-rr}}) and, if it resolves HTTPS records anyway, the HTTPS record for D ({{https-rr}}). The queries are independent and MAY be issued in parallel.
3. The client browses `_ard._tcp.D` ({{dns-sd}}) and resolves each service instance it finds.
4. The client requests "https://D/.well-known/ard" ({{well-known}}). This step MAY start in parallel with steps 2 and 3; a client already connecting to the origin pays nothing for it.
5. If steps 2 to 4 returned nothing, the client sends a HEAD request to "https://D/" and examines the Link header field for the "ard" relation ({{link-relation}}).

A client attached to a local network with no domain name browses "_ard._tcp.local." over Multicast DNS ({{mdns}}). It MAY also query the domain enumeration names of {{Section 11 of RFC6763}} over Multicast DNS to learn a unicast DNS-SD domain for the network and then continue with step 3 for that domain.

The procedure yields a set of entry points with sources. The default order is: configuration first, then DNS answers that were validated with DNSSEC {{RFC4033}}, then responses from the publisher's own origin (steps 4 and 5), then unvalidated DNS answers, then Multicast DNS responses. Within a source, SvcPriority and SRV priority order the candidates. A client MAY apply local policy, for instance to prefer catalogs reachable without leaving the local network.

An entry point that fails, because the URI does not answer, the response is not a catalog, or the checks of {{security}} fail, is marked against its source. A client MUST NOT retry a failed entry point from the same source before a back-off interval, MUST NOT issue the DNS queries of steps 2 and 3 for the same D more often than the TTLs of the answers it received allow, and MUST NOT repeat the requests of steps 4 and 5 while a stored response is fresh ({{RFC9111}}). These rules follow {{Section 4.1 of RFC9176}}, whose candidates are "more or less educated guesses" and whose failures are therefore rate-limited.

## Indirection Depth and Outcomes {#depth}

A client follows at most one AliasMode indirection in the DNS and at most one HTTP redirect per entry point. A second indirection of either kind ends the attempt for that entry point. These limits keep initial contact to a bounded number of round trips and deny an attacker who controls one record or one response the ability to send the client on a chain.

Each attempt to turn a hint into an entry point ends in one of three outcomes, which the client distinguishes so that local policy and the rate limiting above can act on them:

{:vspace}
Entry point:
: The URI returned an ARD catalog from an authenticated origin.

No entry point:
: The URI did not answer, returned something other than a catalog, exceeded the depth limit, or failed the checks of {{security}}.

Not permitted:
: The client's own retrieval policy did not allow the fetch, for instance because the host is not on an allow-list the client applies to unvalidated DNS answers. The hint is kept with its source so that the policy decision can be revisited; it is not counted as a failure of the source.

# Security Considerations {#security}

Initial contact runs before any authenticated relationship exists between the client and the publisher. Each mechanism gives an attacker who controls the channel a way to point the client at a catalog of their choosing. The response of this document is the same in every case: the client treats the result as a hint, retrieves the catalog from the URI, authenticates the origin, and leaves the question of which publisher the catalog speaks for to the catalog content as specified in {{ARD}}.

## Hints and Authority {#sec-hints}

A client MUST authenticate the TLS server for the host named in the entry point URI, following {{Section 4.3.3 of RFC9110}}. For the well-known URI, the link relation, and the HTTPS record ({{http-mechanisms}}, {{https-rr}}), that host is the publisher's own domain, and a successful connection shows that the catalog is served by whoever controls the domain's certificate.

For the index record ({{index-rr}}) and for DNS-SD ({{dns-sd}}), the host in the URI is whatever the DNS said it was. A spoofed answer can direct the client to a host for which the attacker holds a valid certificate, and TLS then authenticates the wrong party correctly. A client SHOULD validate DNS answers with DNSSEC {{RFC4033}} where the zone is signed and SHOULD rank unvalidated answers below validated ones ({{procedure}}). Beyond that, this document does not establish that a catalog reached through `_index._agents.example.com` speaks for "example.com"; the source the client recorded is the input to the publisher check that {{ARD}} defines, and a catalog that fails that check is discarded there. Initial contact finds candidates.

Carrying a digest or a public key for the catalog in the DNS record, as {{I-D.nemethi-dawn-aid}} and {{I-D.besleaga-agentic-knowledge-wellknown}} do for their objects, was considered and not adopted: a catalog changes with every published entry, and a digest in a record with a TTL of hours would fail on each change.

## Local Network Discovery {#sec-local}

Any host on the link can answer a Multicast DNS query, and link-local names carry no certificates. A client MUST treat entry points learned over multicast as the least trusted source. It SHOULD prefer entry points whose URI names a host it can authenticate with a certificate, as {{mdns}} recommends publishers to advertise, and MAY apply local policy such as a pinned key or an allow-list of hosts for networks it manages. A catalog found over multicast is a list of candidates to be verified, not evidence that the agents in it are present on the network or operated by the network's owner.

Multicast queries are an amplification vector: one request produces a response from every host that matches. Clients follow the query rate limits of {{RFC6762}}.

## Downgrade {#sec-downgrade}

A client MUST NOT fall back to "http" when an "https" entry point fails. A client MUST NOT accept an entry point whose scheme is "http" from any mechanism in this document. The "alpn" key in SVCB and HTTPS records selects the HTTP version, not the presence of TLS.

## Well-Known URI Squatting {#sec-well-known}

The well-known URI is served by whoever controls the origin, which on shared hosting may be a tenant rather than the domain owner. {{Section 4 of RFC8615}} describes the risk. The publisher check of {{ARD}} applies to catalogs found this way as to any other; a tenant can serve a catalog but cannot make its entries verify as the domain owner's.

# Privacy Considerations {#privacy}

A DNS query for `_index._agents.example.com` or `_ard._tcp.example.com` tells the resolver and anyone observing the path that the client is looking for the agents of example.com. Encrypted DNS transports, discovered as in {{RFC9462}}, limit the observers to the resolver. The HTTPS query of step 2 and the well-known fetch of step 4 are indistinguishable from an ordinary connection to the domain.

Browsing over Multicast DNS announces to the whole link that the client is looking for agent catalogs, and a host that answers announces that it offers one. Deployments where that is sensitive use unicast DNS-SD through a Discovery Proxy {{RFC8766}} with access control on the zone, or configuration.

The service instance names under `_ard._tcp.<domain>` can be enumerated by anyone. That is intended: they name catalogs a publisher chose to make discoverable, not people or individual agents.

Retrieving the catalog reveals the client's address to the publisher. The catalog itself and anything the client does with it are outside this document.

# IANA Considerations {#iana}

## Well-Known URI {#iana-well-known}

IANA is asked to register the following entry in the "Well-Known URIs" registry defined in {{RFC8615}}:

{:vspace}
URI suffix:
: ard

Change controller:
: IETF

Specification document:
: This document, {{well-known}}. The format of the resource is defined in {{ARD}}.

Status:
: permanent

Related information:
: The resource is an ARD catalog. Clients also locate it through the mechanisms of this document.

## Link Relation {#iana-link-relation}

IANA is asked to register the following entry in the "Link Relations" registry defined in {{RFC8288}}:

{:vspace}
Relation name:
: ard

Description:
: Refers to an Agent Resource Discovery (ARD) catalog listing agent resources offered by the publisher of the link context.

Reference:
: This document, {{link-relation}}.

## Service Name {#iana-service-name}

IANA is asked to register the following service name in the "Service Name and Transport Protocol Port Number Registry" defined in {{RFC6335}}, without an associated port number:

{:vspace}
Service name:
: ard

Transport protocol:
: tcp

Assignee:
: IESG

Contact:
: IETF Chair

Description:
: Agent Resource Discovery (ARD) catalog

Reference:
: This document, {{dns-sd}}.

--- back

# Related Work {#related}

{{I-D.jimenez-dawn-discovery-landscape}} surveys agent discovery mechanisms and separates lookup, name, description, trust, and interaction. Initial contact as defined here is the lookup component for the case where the result is a catalog rather than an agent. The mechanisms below address the same step.

DNS for AI Discovery {{I-D.mozleywilliams-dnsop-dnsaid}} publishes agents as SVCB records under their own names and an organization index under `_index._agents.<domain>`, whose TargetName points at a host that serves an index; the index format is out of its scope, and {{index-rr}} fills that slot with an ARD catalog. DNS-AID also keeps a TXT fallback from SVCB for resolvers that do not yet support the newer type; this document defines no TXT form, since the DNS-SD records of {{dns-sd}} already give a path on such resolvers.

Agent Identity and Discovery {{I-D.nemethi-dawn-aid}} answers the single-agent question with a TXT record at `_agent.<domain>` carrying the endpoint URI, protocol token, and a public key, and resolves in one hop with a fixed set of failure outcomes; {{depth}} follows that shape. {{I-D.morrison-mcp-dns-discovery}} does the same for MCP servers with a TXT record at `_mcp.<domain>` next to a well-known server card. DNS-Based Agent Naming {{I-D.seethiraju-dawn-dan}} defines two new resource record types, AIDISCA for an agent's connection and certificate data and AIINDEX for an index of agent names. All three locate agents directly; none defines a catalog entry point, and this document defines no new record types.

{{I-D.jakab-dawn-agent-discovery-mdns}} browses for agents on the local link under "_agent._tcp" and carries the agent protocol in a "proto" TXT key with a pointer to the agent's full description. Its authors, those of DNS-AID, and those of {{I-D.morrison-mcp-dns-discovery}} are aligning one set of key names for the agent protocol family and the transport across the TXT and SVCB carriers, with a registry to hold the values. The keys of {{dns-sd}} describe a catalog rather than an agent and stay private to the "_ard._tcp" service type; should DAWN create that registry, they can be listed there.

{{I-D.zahed-acap}} publishes an agent capability document at a well-known URI and signs it with the operator's key so that a document hosted by a provider is bound to the operator rather than to the host. That is the question this document hands to {{ARD}} for catalogs. {{I-D.pro-adp-agent-discovery}} publishes a single well-known discovery document for an operator. {{I-D.besleaga-agentic-knowledge-wellknown}} publishes an {{RFC9264}} link set at a well-known URI under a profile URI, with a digest on each link; it is the closest existing shape to publishing an ARD catalog as an {{RFC9727}} API catalog, which {{open-issues}} records as open.

{{Section 4.1 of RFC9176}} lists how a CoRE endpoint finds a Resource Directory: configuration, an IPv6 Router Advertisement option, DNS-SD under "_core-rd._udp" and related service names, and a multicast query for "rt=core.rd*". {{static}} and {{dns-sd}} are the ARD counterparts; {{provided-domain}} takes the place of the Router Advertisement option by reusing the search domain the network already provides. Discovery through the CoRE Link Format and multicast CoAP for constrained networks is not specified in this document.

{{RFC9461}} and {{RFC9462}} are the SVCB protocol mapping and the discovery procedure for encrypted DNS resolvers; {{index-rr}} follows the form of the former, and {{procedure}} the form of the latter.

# Open Issues {#open-issues}

This section records questions to be settled before the document is stable. It is to be removed before publication.

1. API catalog profile. Issue #2 on the ARD repository proposes publishing the catalog as an API catalog {{RFC9727}} under "/.well-known/api-catalog" with an ARD profile. If that is adopted, this document registers no suffix and {{well-known}} points at RFC 9727 with the profile.
2. Index label. {{index-rr}} depends on the DNS-AID authors agreeing that an ARD catalog is a valid index at `_index._agents`. The fallback is a label of this document's own, "_ard", registered in the "Underscored and Globally Scoped DNS Node Names" registry {{RFC8552}} with a protocol mapping equivalent to {{index-rr}}. One label in DAWN is better than two, so the fallback is taken only if the agreement is not reached.
3. Ownership of registrations. {{ARD}} at the time of writing also requests a well-known suffix and a link relation. After the split into initial contact, lookup, and registration documents, one document carries them.
4. Reference status. {{ARD}} and {{I-D.mozleywilliams-dnsop-dnsaid}} are individual drafts and are cited informatively in this version. The catalog representation that {{ARD}} defines is what an entry point returns, so {{ARD}} becomes a normative reference when the companion documents are adopted together; the index label of {{index-rr}} becomes normative, or is replaced by this document's own label, when the DNS-AID question is settled.

# Acknowledgments
{:numbered="false"}

The split of the ARD work into initial contact, lookup, and registration documents was proposed by Jari Arkko. R.V. Guha co-wrote the ARD specification this document attaches to. Wes Hardaker and Sam Sharaf took part in the discussions that shaped the scope. Jim Mozley and Daniel King's work on the organization index and on the "well-known" SvcParamKey provided the DNS bindings used here. The depth limit and the fixed outcomes follow a discussion on the DAWN list started by Enrique Somoza and carried by Francesco Marinoni Moretto and Balazs Nemethi.
