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
  github: "jaimejim/ietf-draft-ard-initial-contact"
  latest: "https://jaimejim.github.io/ietf-draft-ard-initial-contact/draft-jimenez-ard-initial-contact.html"

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
  RFC2308:
  RFC4035:
  RFC4343:
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
  ARD-SPEC:
    title: "Agentic Resource Discovery Specification, v0.91"
    author:
      - org: ARD Project
    date: 2026-10
    target: https://agenticresourcediscovery.org/spec/
  DNS-AID-IMPL:
    title: "dns-aid-core: DNS-based Agent Identification and Discovery, reference implementation"
    author:
      - org: DNS-AID Project
    date: 2026-09
    target: https://github.com/dns-aid/dns-aid-core
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

This document specifies how a client obtains the URI of an Agent Resource Discovery (ARD) catalog. It defines a well-known URI, an HTTP link relation, the use of DNS Service Binding records under the "_agents" label defined by DNS for AI Discovery, and a DNS-Based Service Discovery (DNS-SD) service type for use over unicast DNS and Multicast DNS. Each mechanism yields a set of catalog URIs together with the source from which each URI was learned. Information obtained during initial contact is a hint that the client verifies when it retrieves the catalog from its origin. The catalog format, the lookup interface, and the binding of a catalog to its publisher are specified in the companion ARD documents.

--- middle

# Introduction {#intro}

Agent Resource Discovery (ARD) {{ARD}} defines a catalog of agent resources, a document served over HTTPS in which a publisher lists the agents, tool servers, and skills it offers. Each entry points at the artifact that describes the resource in its native protocol, such as an Agent Card {{A2A}} or an MCP server description {{MCP}}. ARD also defines a lookup interface over the catalog. Both require that the client holds the URI of the catalog.

ARD does not specify how a client obtains that URI. The applicable IETF mechanisms, well-known URIs {{RFC8615}}, web linking {{RFC8288}}, Service Binding records {{RFC9460}}, and DNS-SD {{RFC6763}} with Multicast DNS {{RFC6762}}, each require an application-specific binding that defines the names to query, the parameters to publish, and the interpretation of the answer.

This document defines the following mechanisms for obtaining the URI of an ARD catalog:

* a well-known URI {{RFC8615}} with the suffix "ard.json" ({{well-known}});
* a link relation {{RFC8288}}, "ard", whose target is an ARD catalog ({{link-relation}});
* the use of SVCB and HTTPS records {{RFC9460}} under the "_agents" label defined by DNS for AI Discovery {{I-D.mozleywilliams-dnsop-dnsaid}} ({{pointer-rr}}, {{https-rr}});
* a DNS-SD service type {{RFC6763}}, "_ard._tcp", for use over unicast DNS and Multicast DNS {{RFC6762}} ({{dns-sd}}, {{mdns}}).

{{procedure}} specifies how a client combines these mechanisms. The DAWN charter {{DAWN-CHARTER}} refers to this step as "initial discovery"; this document uses the term "initial contact". The mechanisms cover the three deployment contexts the charter identifies: the local network, an organization's own infrastructure, and discovery between organizations over the public Internet.

This document does not specify the catalog representation, the lookup or search interfaces, the registration of entries, or how a catalog is bound to its publisher; these are specified in {{ARD}} and {{I-D.jimenez-agent-directory}}. It defines no new DNS resource record types, SvcParamKeys, or transport protocols. All entry point URIs use the "https" scheme.

# Conventions and Definitions {#definitions}

{::boilerplate bcp14-tagged}

This document uses the DNS terminology of {{RFC9499}}, the DNS-SD terms "service type", "service instance", "browse", and "resolve" from {{RFC6763}}, and the HTTP terms "origin" and "authoritative" from {{Sections 4.3.1 and 4.3.3 of RFC9110}}.

{:vspace}
ARD catalog:
: A document listing agent resources in the format defined in {{ARD}}.

Entry point:
: The URI of an ARD catalog, together with the source from which the client learned it ({{entry-point}}).

Publisher:
: The party that controls a domain name and publishes a catalog of agent resources under it.

Client:
: Software that needs an ARD entry point.

Initial contact:
: The process by which a client obtains one or more entry points, starting from a domain name, a local network attachment, or configuration.

Hint:
: Information about an entry point obtained from a source other than the entry point's own origin, such as a DNS answer, a multicast response, or a link in a third-party document.

# The Entry Point {#entry-point}

Every mechanism in this document yields zero or more entry points. An entry point consists of two elements:

{:vspace}
URI:
: The "https" URI {{RFC9110}} of the catalog. Retrieving it returns an ARD catalog in a representation defined by {{ARD}}.

Source:
: The mechanism that produced the entry point and, where applicable, the DNS name or network interface it came from. The client retains the source in order to rank candidates ({{procedure}}), to rate-limit failing sources, and to apply local policy.

An entry point is a hint until the client has retrieved the catalog from the URI and authenticated the origin ({{security}}). A DNS answer or a multicast response does not make a catalog authoritative for a publisher. The publisher of a catalog is established by the catalog content, as specified in {{ARD}}.

A domain can publish more than one catalog. Each mechanism can return several entry points, and the client treats them as a set. A catalog can link to further catalogs; following those links is part of lookup and is outside the scope of this document.

# Discovery Mechanisms {#mechanisms}

The well-known URI of {{well-known}} is the mandatory baseline. A publisher that makes its catalog discoverable MUST serve it at the well-known URI, directly or through one redirect, and every client MUST implement the well-known fetch. The other mechanisms are OPTIONAL for publishers. A client that supports discovery of catalogs on the local network MUST implement the Multicast DNS browse of {{mdns}}.

## Configured Entry Points {#static}

A client MAY be configured directly with one or more entry points, for instance by an operator, by a device profile, or by the application that includes the client. A configured entry point has the source "configuration", is tried before any discovered entry point, and is verified like any other. Configuration is also the means by which a client learns about catalogs that a publisher does not make discoverable.

## Well-Known URI {#well-known}

A publisher makes its catalog available at the well-known URI {{RFC8615}} with the suffix "ard.json". For the domain example.com, the well-known URI is:

~~~
https://example.com/.well-known/ard.json
~~~

A publisher supporting this mechanism MUST respond to a GET request for this URI with an ARD catalog or with a redirect to one. The catalog carries the media type defined in {{ARD}}, and a client SHOULD send it in the Accept header field. The client MUST follow at most one redirect (301, 302, 303, 307, or 308 with a Location field, {{Section 15.4 of RFC9110}}) and records the final URI as the entry point. A response with another media type, or a redirect to a further redirect, means that there is no entry point at this origin ({{depth}}). A server that hosts no catalog SHOULD respond with 404 (Not Found) and MAY include Problem Details {{RFC9457}}.

Responses to the well-known URI, including redirects and 404 responses, are cacheable under {{RFC9111}}. A client MUST NOT request the URI again while a stored response is fresh. A freshness lifetime of hours suits a stable catalog location.

The scope of a well-known URI is its origin ({{Section 3 of RFC8615}}); a catalog at "https://example.com/.well-known/ard.json" provides no information about "https://agents.example.com/". A publisher with catalogs on several hosts can serve a catalog at the apex that links to the others, or can enumerate them with DNS-SD ({{dns-sd}}).

The registration of the suffix is in {{iana-well-known}}.

## Link Relation {#link-relation}

A publisher MAY include a link to a catalog in any HTTP response using the "ard" link relation {{RFC8288}} in a Link header field. The link target is an ARD catalog. A publisher SHOULD respond to a HEAD request for the root resource of its origin with a Link header field carrying the relation, following {{Section 2 of RFC9727}}. The following is an example:

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

The client reads the Link field of the root response whatever its status code and does not follow a redirect of the root. Links in a response from the publisher's own origin have that origin as their source. Links in third-party documents are hints with the third party as their source. The registration of the relation is in {{iana-link-relation}}.

## DNS-Based Mechanisms {#dns-mechanisms}

DNS records allow a publisher to advertise an entry point before the client opens a connection, and to place the catalog on a host other than the domain apex without a redirect.

### Catalog Pointer Record {#pointer-rr}

DNS for AI Discovery (DNS-AID) {{I-D.mozleywilliams-dnsop-dnsaid}} places an organization's agent-related DNS records under the underscored label "_agents". This document uses the name `_catalog._agents.<domain>`, as published by the DNS-AID reference implementation {{DNS-AID-IMPL}}, for a Service Binding (SVCB) record {{RFC9460}} whose TargetName serves an ARD catalog at the well-known URI. The status of this name is discussed in {{open-issues}}. The following is an example for example.com:

~~~
_catalog._agents.example.com. 3600 IN SVCB 1 catalog.example.net. (
    alpn="h2"
)
~~~

The client forms the entry point as follows:

* The scheme is "https".
* The authority is the TargetName, with the port from the "port" key or 443. The TargetName MUST be a host name without underscore labels, as in {{Section 3.2 of I-D.mozleywilliams-dnsop-dnsaid}}, so that a publicly issued certificate can name it. A record whose TargetName is "." yields no entry point.
* The path is "/.well-known/ard.json". When the record carries the "well-known" SvcParamKey {{I-D.mk-dnsop-svcb-well-known}} with a value that includes "ard.json", the client can conclude that the catalog is served at that path. Otherwise the client learns this from the response. The key has no registered number yet; tests use a Private Use number ({{Section 14.3.2 of RFC9460}}).
* Address records of the TargetName absent from the Additional section ({{Section 4.1 of RFC9460}}) are resolved by the client.
* The "alpn", "port", "ipv4hint", "ipv6hint", and "ech" keys apply with their {{RFC9460}} semantics. The "mandatory" key is processed as in {{Section 8 of RFC9460}}. Other keys are ignored.
* One AliasMode indirection is followed ({{Section 2.4.2 of RFC9460}}); a second ends the attempt ({{depth}}). An AliasMode record whose TargetName is "." yields no entry point.

In the example, the entry point is "https://catalog.example.net/.well-known/ard.json". The client validates the TLS certificate for "catalog.example.net" and records `_catalog._agents.example.com` as the source. An RRset MAY contain several ServiceMode records; each yields one entry point, and SvcPriority orders them. If no catalog is found at the well-known path of a TargetName, the record yields no entry point. A client MAY also query the DNS-AID organization index `_index._agents.<domain>` and treat an ARD catalog found at its TargetName in the same way.

### HTTPS Record at the Apex {#https-rr}

A publisher whose catalog is served at the origin of a domain name MAY list the suffix "ard.json" in the "well-known" SvcParamKey {{I-D.mk-dnsop-svcb-well-known}} of the HTTPS record {{RFC9460}} of that name:

~~~
example.com. 3600 IN HTTPS 1 . (
    alpn="h2,h3"
    well-known="ard.json"
)
~~~

A client that resolves HTTPS records when connecting to an origin can determine from the key that the well-known fetch of {{well-known}} will succeed, and MAY skip the other mechanisms. The record yields no entry point by itself and does not affect ranking ({{procedure}}). The certificate is validated for "example.com" ({{Section 9 of RFC9460}}). A record without the key carries no information about the catalog.

### DNS-SD Service Type "_ard._tcp" {#dns-sd}

A publisher MAY advertise catalogs as DNS-SD service instances {{RFC6763}} of the service type "_ard._tcp", for instance to name and enumerate several catalogs, or in networks that run DNS-SD. A client browses by querying PTR records at `_ard._tcp.<domain>` and resolves each service instance name to its SRV and TXT records. The following is an example for example.com with two catalogs:

~~~
_ard._tcp.example.com. 3600 IN PTR Travel._ard._tcp.example.com.
_ard._tcp.example.com. 3600 IN PTR Tools._ard._tcp.example.com.

Travel._ard._tcp.example.com. 3600 IN SRV 0 0 443 (
    catalog.example.net. )
Travel._ard._tcp.example.com. 3600 IN TXT (
    "txtvers=1"
    "path=/.well-known/ard.json"
)
~~~

The TXT record carries the following keys, with the syntax of {{Section 6 of RFC6763}}:

{:vspace}
txtvers:
: The version of this key set. This document defines version 1. Absent, version 1 is assumed. A client MUST ignore records with a version it does not support.

path:
: The path and optional query component of the entry point, as an absolute path {{RFC3986}}. When the key is absent, the path is "/.well-known/ard.json". This catalog need not be the one at the well-known URI of the same host.

The client forms the entry point URI from the scheme "https", the SRV target as the host, the SRV port (omitted when it is 443), and the path. This document defines no "_ard._udp" service. The service name "ard" is registered in {{iana-service-name}}.

Service instance names such as "Travel" are human-readable labels that {{RFC6763}} allows to change and whose case a server need not preserve ({{RFC4343}}). A client SHOULD NOT use an instance name as a persistent identifier of a catalog.

## Local Network Mechanisms {#local-mechanisms}

### Network-Provided Domain Name {#provided-domain}

A client without a domain name can obtain one from the network through the DHCPv4 Domain Name option ({{Section 3.17 of RFC2132}}), the DHCPv6 Domain Search List option {{RFC3646}}, or the DNS Search List option in IPv6 Router Advertisements {{RFC8106}}. The client treats such a name as the domain D of {{procedure}}. The name is a hint from the network, and the client records it as such.

### Multicast DNS {#mdns}

On the local link, a client browses for "_ard._tcp.local." over Multicast DNS {{RFC6762}}, using the same PTR, SRV, and TXT records as in {{dns-sd}}. Names under "local." do not appear in certificates issued by public CAs. A publisher that advertises over Multicast DNS SHOULD set the SRV target to a unicast DNS name for which it holds a certificate, so that the entry point URI names a host the client can authenticate. A client MAY use the address records in the multicast answer ({{Section 12.2 of RFC6763}}) to reach the target; TLS authenticates the host either way ({{sec-hints}}). A responder that accepts only "local." targets yields entry points the client cannot authenticate ({{sec-local}}). A browse runs for a bounded time; later answers are new hints. Where a Discovery Proxy {{RFC8766}} is deployed, the client can use {{dns-sd}} instead. Entry points learned over Multicast DNS carry the network interface as their source ({{sec-local}}).

{{I-D.jakab-dawn-agent-discovery-mdns}} describes browsing for individual agents under "_agent._tcp". The two service types coexist.

# Client Procedure {#procedure}

The procedure in this section is a RECOMMENDED default. The well-known fetch of step 4, the depth limits of {{depth}}, and the rate limiting below are requirements on every client. A client MAY reorder or omit the other steps under local policy.

A client that holds a domain name D, from configuration, from the user, or from the network ({{provided-domain}}), proceeds as follows. Steps that return entry points do not stop the procedure.

1. The client uses configured entry points for D ({{static}}) first.
2. The client queries the SVCB record for `_catalog._agents.D` ({{pointer-rr}}) and, if it resolves HTTPS records in any case, the HTTPS record for D ({{https-rr}}). It MAY also query `_index._agents.D`. The queries MAY be issued in parallel.
3. The client browses `_ard._tcp.D` ({{dns-sd}}).
4. The client requests "https://D/.well-known/ard.json" ({{well-known}}). This step MAY be performed in parallel with steps 2 and 3.
5. If steps 2 to 4 yield no entry point, the client sends a HEAD request to "https://D/" and examines the Link header field for the "ard" relation ({{link-relation}}).

A client without a domain name browses "_ard._tcp.local." over Multicast DNS ({{mdns}}).

The procedure ends when every step has returned. A client attempts each distinct URI once per run and records all its sources.

The default order of preference is: configuration, then DNS answers validated with DNSSEC {{RFC4033}}, then responses from the publisher's own origin (steps 4 and 5), then unvalidated DNS answers, then Multicast DNS responses. An answer is validated when the client validated it or received it with the AD bit set from a trusted validating resolver over a secure channel ({{Section 4.9.3 of RFC4035}}); Insecure and Indeterminate answers ({{Section 4.3 of RFC4035}}) are unvalidated, and Bogus answers are discarded. An entry point is validated when every answer used to form its URI was; address records do not count, since TLS authenticates the host. Within a tier, step order applies; within a source, SvcPriority and SRV priority. A client MAY apply local policy.

An entry point fails if the URI does not respond, if the response is not a catalog, or if the checks of {{security}} fail. A client MUST NOT retry a failed entry point from the same source before a back-off interval of at least 30 seconds. A client MUST NOT issue the DNS queries of steps 2 and 3 for the same D more often than the TTLs of the answers allow, including negative answers ({{RFC2308}}) and the DNSKEY and DS queries of validation. A client MUST NOT repeat the requests of steps 4 and 5 while a stored response is fresh ({{RFC9111}}).

## Indirection Depth and Outcomes {#depth}

A client follows at most one AliasMode indirection in the DNS and at most one HTTP redirect per entry point, from any mechanism; the two limits are independent. A second indirection of either kind ends the attempt. This bounds the number of round trips and prevents an attacker who controls one record or one response from leading the client through a chain of indirections.

Each attempt to resolve a hint has one of three outcomes:

{:vspace}
Entry point:
: The URI returned an ARD catalog from an authenticated origin.

No entry point:
: The URI did not respond, returned something other than a catalog, exceeded the depth limit, or failed the checks of {{security}}. The failure counts against the source.

Not permitted:
: The client's own policy did not allow the fetch, for instance a host under "local." that no certificate can authenticate ({{sec-local}}), or a host not on an allow-list. The hint is kept with its source and does not count as a failure of the source.

# Security Considerations {#security}

Initial contact takes place before any authenticated relationship exists between the client and the publisher. In each mechanism, an attacker who controls the channel can direct the client to a catalog of the attacker's choosing. The mitigation is the same for all mechanisms: the client treats the result as a hint, retrieves the catalog from the URI, authenticates the origin, and relies on the catalog content, as specified in {{ARD}}, to determine the publisher of the catalog.

## Hints and Authority {#sec-hints}

A client MUST authenticate the TLS server for the host named in the entry point URI ({{Section 4.3.3 of RFC9110}}). For the well-known URI and the HTTPS record, that host is the publisher's own domain. For the pointer record, for DNS-SD, and for a link whose target is on another origin, the host comes from the answer or the link, and a spoofed answer can direct the client to a host for which the attacker holds a valid certificate. A client SHOULD validate DNS answers with DNSSEC {{RFC4033}} where the zone is signed and SHOULD rank unvalidated answers below validated ones ({{procedure}}). This document does not establish that a catalog reached through `_catalog._agents.example.com` is published by "example.com"; the recorded source is the input to the publisher check that {{ARD}} defines.

Carrying a digest or a public key for the catalog in the DNS record, as {{I-D.nemethi-dawn-aid}} does for its objects, was considered and not adopted, since a catalog changes with every published entry.

## Local Network Discovery {#sec-local}

Any host on the link can respond to a Multicast DNS query. A client MUST treat entry points learned over multicast as the least trusted source. It SHOULD prefer entry points whose URI names a host it can authenticate with a certificate, and MAY apply local policy, such as a pinned key or an allow-list of hosts. A catalog found over multicast does not establish that the agents listed in it are present on the network or operated by the network's owner. A multicast query produces a response from every matching host on the link; clients MUST follow the query rate limits of {{RFC6762}}.

## Downgrade {#sec-downgrade}

A client MUST NOT fall back to "http" when an "https" entry point fails, and MUST NOT accept an entry point whose scheme is "http". The "alpn" key in SVCB and HTTPS records selects the HTTP version; it does not affect the requirement for TLS.

## Well-Known URI Squatting {#sec-well-known}

On shared hosting, the well-known URI can be served by a tenant rather than the domain owner ({{Section 4 of RFC8615}}). The publisher check of {{ARD}} applies to catalogs found through the well-known URI as it does to any other; a tenant can serve a catalog, but its entries will not pass the publisher check as entries of the domain owner.

# Privacy Considerations {#privacy}

A DNS query for `_catalog._agents.example.com` or `_ard._tcp.example.com` reveals to the resolver, and to any observer on the path, that the client is looking for the agents of example.com. Encrypted DNS transports, discovered as described in {{RFC9462}}, limit the observers to the resolver. The well-known fetch is indistinguishable from an ordinary connection to the domain. The TLS Server Name Indication reveals the TargetName host unless the "ech" key is used, and DNSSEC validation adds DNSKEY and DS queries to the parent zones.

Browsing over Multicast DNS reveals to all hosts on the link that the client is looking for agent catalogs, and a responding host reveals that it offers one. Deployments where this is a concern can use unicast DNS-SD through a Discovery Proxy {{RFC8766}} with access control on the zone, or configuration. The service instance names under `_ard._tcp.<domain>` can be enumerated by any party; they identify catalogs that a publisher has chosen to make discoverable, and they do not identify people or individual agents.

Retrieving the catalog reveals the client's address to the publisher.

# IANA Considerations {#iana}

## Well-Known URI {#iana-well-known}

IANA is asked to register the following entry in the "Well-Known URIs" registry defined in {{RFC8615}}:

{:vspace}
URI suffix:
: ard.json

Change controller:
: IETF

Specification document:
: This document, {{well-known}}. The format of the resource is defined in {{ARD}}.

Status:
: permanent

Related information:
: The resource is an ARD catalog.

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

{{I-D.jimenez-dawn-discovery-landscape}} surveys agent discovery mechanisms and separates lookup, name, description, trust, and interaction. Initial contact is the lookup component for the case where the result is a catalog. The entry point of {{entry-point}} is a subset of the minimum discoverable information of {{I-D.cui-dawn-mdi-model}}, the well-known URI is the predictable entry point that REQ-PROTO-4 of {{I-D.king-dawn-requirements}} asks for, and the terminology of {{I-D.farrel-dawn-terminology}} applies.

DNS-AID {{I-D.mozleywilliams-dnsop-dnsaid}} publishes agents as SVCB records and an organization index under `_index._agents.<domain>`. Its reference implementation {{DNS-AID-IMPL}} publishes `_catalog._agents` next to it, follows an off-domain pointer only when the record is DNSSEC-validated or the catalog is signed against the domain's key set, and refuses redirects. {{pointer-rr}} adopts its label, {{depth}} allows one redirect, and the trust decision for off-domain pointers is left to the publisher check of {{ARD}}. The ARD specification {{ARD-SPEC}}, from which {{ARD}} derives, requires the well-known fetch of "/.well-known/ard.json", lists `_entries._agents` for a static entry source, and publishes an SVCB record at `_ard._tcp.<domain>`; this document uses that name only as a DNS-SD service type.

{{I-D.nemethi-dawn-aid}}, {{I-D.morrison-mcp-dns-discovery}}, and {{I-D.seethiraju-dawn-dan}} locate individual agents or MCP servers through DNS records at `_agent.<domain>`, at `_mcp.<domain>`, or in new resource record types; none defines a catalog entry point. {{I-D.jakab-dawn-agent-discovery-mdns}} browses for agents on the local link under "_agent._tcp". {{I-D.zahed-acap}}, {{I-D.pro-adp-agent-discovery}}, and {{I-D.besleaga-agentic-knowledge-wellknown}} publish operator-level discovery documents at well-known URIs. The last publishes an {{RFC9264}} link set, which is the closest existing design to publishing an ARD catalog as an {{RFC9727}} API catalog ({{open-issues}}).

{{Section 4.1 of RFC9176}} lists how a CoRE endpoint finds a Resource Directory: configuration, a Router Advertisement option, DNS-SD, and multicast. {{static}}, {{provided-domain}}, {{dns-sd}}, and {{mdns}} are the ARD counterparts. {{RFC9461}} and {{RFC9462}} are the SVCB mapping and the discovery procedure for encrypted DNS resolvers; {{pointer-rr}} and {{procedure}} follow their form.

# Open Issues {#open-issues}

The following questions are to be settled before the document is stable. This section is to be removed before publication.

1. API catalog profile. Issue #2 on the ARD repository proposes publishing the catalog as an {{RFC9727}} API catalog under "/.well-known/api-catalog" with an ARD profile. If adopted, this document registers no suffix.
2. Pointer label. `_index._agents` (DNS-AID), `_catalog._agents` (its reference implementation), and `_entries._agents` ({{ARD-SPEC}}) name the same pointer. This document uses `_catalog._agents` because it is deployed, and asks DNS-AID, as owner of "_agents" in the {{RFC8552}} registry, to list it. The fallback is a label of this document's own, "_ard".
3. Suffix. "ard.json" matches {{ARD-SPEC}} and deployed code. A suffix without the extension, "ard", was considered.
4. Ownership of registrations. {{ARD}} also requests a well-known suffix and a link relation. After the split into initial contact, lookup, and registration documents, one document carries them.
5. Reference status. {{ARD}} and {{I-D.mozleywilliams-dnsop-dnsaid}} are individual drafts cited informatively. {{ARD}} becomes a normative reference when the companion documents are adopted together.
6. SvcParamKey number. The "well-known" key has no registered number; the examples in {{pointer-rr}} and {{https-rr}} cannot be loaded into a zone until it does.

# Acknowledgments
{:numbered="false"}

The split of the ARD work into initial contact, lookup, and registration documents was proposed by Jari Arkko. R.V. Guha co-wrote the ARD specification this document builds on. Wes Hardaker and Sam Sharaf took part in the discussions that shaped the scope. The work of Jim Mozley and Daniel King on the organization index and on the "well-known" SvcParamKey provided the DNS bindings used here. The depth limit and the fixed outcomes follow a discussion on the DAWN list started by Enrique Somoza and carried by Francesco Marinoni Moretto and Balazs Nemethi.
