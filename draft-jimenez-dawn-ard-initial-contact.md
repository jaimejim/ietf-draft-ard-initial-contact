---
title: "Agent Resource Discovery (ARD): Initial Contact"
abbrev: "ARD Initial Contact"
category: std

docname: draft-jimenez-dawn-ard-initial-contact-latest
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
  type: "Working Group"
  mail: "dawn@ietf.org"
  arch: "https://mailarchive.ietf.org/arch/browse/dawn/"

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
  I-D.mozleywilliams-dnsop-dnsaid:
  ARD:
    title: "Agent Resource Discovery (ARD)"
    author:
      - name: Junjie Bu
      - name: R.V. Guha
      - name: Shaun Smith
      - name: Jaime Jiménez
      - name: Jeffrey Damick
    date: 2026-10
    target: https://datatracker.ietf.org/doc/draft-bu-dawn-ard-discovery/
    seriesinfo:
      Internet-Draft: draft-bu-dawn-ard-discovery
  ARD-ARCH:
    title: "Agent Resource Discovery (ARD) Architecture"
    author:
      - name: Junjie Bu
      - name: R.V. Guha
      - name: Jari Arkko
    date: 2026-10
    target: https://datatracker.ietf.org/doc/draft-bu-dawn-ard-architecture/
    seriesinfo:
      Internet-Draft: draft-bu-dawn-ard-architecture

informative:
  RFC2308:
  RFC4035:
  RFC4343:
  RFC9457:
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
  DAWN-CHARTER:
    title: "Discovery of Agents With Names (DAWN) Charter"
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

In an agent system, agents need to discover other agents, tool servers, and skills. Agent Resource Discovery (ARD) defines a manifest listing such resources and a lookup interface over it. This document specifies how a client (such as an agent) initially discovers an ARD manifest. This discovery is performed through the use of DNS Service Binding records, DNS-Based Service Discovery (DNS-SD), HTTP link relations, or well-known URIs. Each mechanism yields a set of manifest URIs. The manifest format, the lookup interface, and the binding of a manifest to its publisher are specified in the companion ARD documents.

--- middle

# Introduction {#intro}

Agent Resource Discovery (ARD) {{ARD}} defines the manifest, a document served over HTTPS in which a publisher lists agents, tool servers, and skills. Each entry points at the artifact that describes the resource in its native protocol, such as an Agent Card {{A2A}} or an MCP server description {{MCP}}. ARD also defines a lookup interface over the manifest. Both require the URI of the manifest. The ARD architecture is described in {{ARD-ARCH}}.

ARD does not specify how a client obtains that URI. The applicable IETF mechanisms, well-known URIs {{RFC8615}}, web linking {{RFC8288}}, Service Binding records {{RFC9460}}, and DNS-SD {{RFC6763}} with Multicast DNS {{RFC6762}}, each require an application-specific binding that defines the names to query, the parameters to publish, and the interpretation of the answer.

This document defines the following mechanisms for obtaining the URI of an ARD manifest:

* the organization index record `_index._agents` defined by DNS for AI Discovery {{I-D.mozleywilliams-dnsop-dnsaid}}, a Service Binding record {{RFC9460}} with an ARD manifest as its target ({{pointer-rr}});
* a DNS-SD service type {{RFC6763}}, "_ard._tcp", for use over unicast DNS and Multicast DNS {{RFC6762}} ({{dns-sd}}, {{mdns}});
* a well-known URI {{RFC8615}} with the suffix "ard.json" ({{well-known}});
* a link relation {{RFC8288}}, "ard", whose target is an ARD manifest ({{link-relation}}).

{{procedure}} specifies how a client combines these mechanisms. The DAWN charter {{DAWN-CHARTER}} calls this step "initial discovery"; this document uses the term "initial contact" for the same step, and the term "manifest", from {{ARD}}, for the catalog that the charter names as a service that furthers discovery. The mechanisms cover the three deployment contexts the charter identifies: the local network, an organization's own infrastructure, and discovery between organizations over the public Internet.

This document does not specify the manifest representation, the lookup or search interfaces, the registration of entries, or how a manifest is bound to its publisher; these are specified in {{ARD}} and {{I-D.jimenez-agent-directory}}. It defines no new DNS resource record types, underscored node names, SvcParamKeys, or transport protocols. All entry point URIs use the "https" scheme. The mechanisms and the procedure do not depend on the manifest format; the well-known suffix, the media type, and the publisher check are the parts specific to ARD.

# Conventions and Definitions {#definitions}

{::boilerplate bcp14-tagged}

This document uses the DNS terminology of {{RFC9499}}, the DNS-SD terms "service type", "service instance", "browse", and "resolve" from {{RFC6763}}, and the HTTP terms "origin" and "authoritative" from {{Sections 4.3.1 and 4.3.3 of RFC9110}}.

{:vspace}
ARD manifest:
: A document listing agent resources in the format defined in {{ARD}}.

Entry point:
: The URI of an ARD manifest, together with the source from which the client learned it ({{entry-point}}).

Publisher:
: The party that controls a domain name and publishes a manifest of agent resources under it.

Client:
: Software that performs the procedure of this document to obtain an entry point.

Initial contact:
: The process by which a client obtains one or more entry points, starting from a domain name, a local network attachment, or configuration.

Hint:
: Information about an entry point obtained from a source other than the entry point's own origin, such as a DNS answer, a multicast response, or a link in a third-party document.

# The Entry Point {#entry-point}

Every mechanism in this document yields zero or more entry points. An entry point consists of two elements:

{:vspace}
URI:
: The "https" URI {{RFC9110}} of the manifest. Retrieving it returns an ARD manifest in a representation defined by {{ARD}}.

Source:
: The mechanism that produced the entry point and, where applicable, the DNS name or network interface from which it was obtained. The client retains the source to rank entry points ({{procedure}}), to rate-limit failing sources, and to apply local policy.

An entry point is a hint until the client has retrieved the manifest from the URI and authenticated the origin ({{security}}). A DNS answer or a multicast response does not make a manifest authoritative for a publisher. The publisher of each entry is established from the entry itself, as specified in {{ARD}}; the host that serves the manifest establishes no publisher authority.

A domain can publish more than one manifest. Each mechanism can return several entry points, and the client treats them as a set. A manifest can link to further manifests, and can consist of a single entry that points at a registry endpoint {{ARD}}; following those links is part of lookup and is outside the scope of this document. Initial contact ends at the manifest.

# Discovery Mechanisms {#mechanisms}

The well-known URI of {{well-known}} is mandatory to implement. A publisher that makes its manifest discoverable MUST serve it at the well-known URI, directly or through one redirect, and every client MUST implement the well-known fetch. The other mechanisms are OPTIONAL for publishers and supplement the well-known URI: they let a client learn an entry point before it connects, enumerate several manifests, or find a manifest without a domain name. A client that supports discovery of manifests on the local network MUST implement the Multicast DNS browse of {{mdns}}.

The mechanisms of {{dns-mechanisms}} and {{origin-mechanisms}} take a domain name as input. The mechanisms of {{local-mechanisms}} require no domain name.

## Configured Entry Points {#static}

A client MAY be configured directly with one or more entry points, for instance by an operator, by a device profile, or by the application that includes the client. A configured entry point has the source "configuration", is tried before any discovered entry point, and is verified in the same way as a discovered entry point. Configuration is also used for manifests that a publisher does not advertise.

A configured entry point is a URI. The client retrieves it directly; the DNS queries and HTTP requests of steps 2 to 5 of {{procedure}} do not apply to it. A client MAY be configured to use configured entry points only. Such a client does not perform the mechanisms of {{dns-mechanisms}}, {{origin-mechanisms}}, and {{local-mechanisms}}.

## DNS-Based Mechanisms {#dns-mechanisms}

DNS records allow a publisher to advertise an entry point before the client opens a connection, to send the client to a manifest host other than the domain apex without the redirect at the apex, and to enumerate several manifests. The well-known URI of {{well-known}} remains in place: the apex serves the manifest or redirects to it ({{mechanisms}}).

### Organization Index Record {#pointer-rr}

DNS for AI Discovery (DNS-AID) {{I-D.mozleywilliams-dnsop-dnsaid}} defines the organization index: a Service Binding (SVCB) record {{RFC9460}} at `_index._agents.<domain>` whose TargetName identifies a host that serves a registry of the organization's agents. DNS-AID leaves the data served by that host out of scope. This section specifies the case where the host serves an ARD manifest at the well-known URI of {{well-known}}, and how a client that expects a manifest interprets the record. The following is an example for example.com:

~~~
_index._agents.example.com. 3600 IN SVCB 1 ard.example.net. (
    alpn="h2"
)
~~~

The client forms the entry point as follows:

* The scheme is "https".
* The authority is the TargetName, with the port from the "port" key or 443. The TargetName MUST be a host name without underscore labels, as in {{Section 3.2 of I-D.mozleywilliams-dnsop-dnsaid}}, so that a publicly issued certificate can name it. A record whose TargetName is "." yields no entry point.
* The path is "/.well-known/ard.json". The response determines whether a manifest is present.
* Address records of the TargetName absent from the Additional section ({{Section 4.1 of RFC9460}}) are resolved by the client.
* The "mandatory" key is processed as in {{Section 8 of RFC9460}}: a record whose mandatory list names a key the client does not implement is ignored. The "alpn", "port", "ipv4hint", "ipv6hint", and "ech" keys apply with their {{RFC9460}} semantics. Other keys are ignored.
* One AliasMode indirection is followed ({{Section 2.4.2 of RFC9460}}); a second ends the attempt ({{depth}}). An AliasMode record whose TargetName is "." yields no entry point.

In the example, the entry point is "https://ard.example.net/.well-known/ard.json". The client validates the TLS certificate for "ard.example.net" and records `_index._agents.example.com` as the source. An RRset MAY contain several ServiceMode records; each yields one entry point, and SvcPriority orders them. If no manifest is found at the well-known path of a TargetName, the record yields no entry point; the host can still serve an index in another format, which this document does not interpret.

### DNS-SD Service Type "_ard._tcp" {#dns-sd}

A publisher MAY advertise manifests as DNS-SD service instances {{RFC6763}} of the service type "_ard._tcp", for instance to name and enumerate several manifests, or in networks that run DNS-SD. A client browses by querying PTR records at `_ard._tcp.<domain>` and resolves each service instance name to its SRV and TXT records. The following is an example for example.com with two manifests:

~~~
_ard._tcp.example.com. 3600 IN PTR Travel._ard._tcp.example.com.
_ard._tcp.example.com. 3600 IN PTR Tools._ard._tcp.example.com.

Travel._ard._tcp.example.com. 3600 IN SRV 0 0 443 (
    ard.example.net. )
Travel._ard._tcp.example.com. 3600 IN TXT (
    "txtvers=1"
    "path=/.well-known/ard.json"
)
~~~

The TXT record carries the following keys, with the syntax of {{Section 6 of RFC6763}}:

{:vspace}
txtvers:
: The version of this key set. This document defines version 1. When the key is absent, version 1 is assumed. A client MUST ignore records with a version it does not support.

path:
: The path and optional query component of the entry point, as an absolute path {{RFC3986}}. When the key is absent, the path is "/.well-known/ard.json". The manifest at this path can differ from the manifest at the well-known URI of the same host.

The client forms the entry point URI from the scheme "https", the SRV target as the host, the SRV port (omitted when it is 443), and the path. This document defines no "_ard._udp" service. The service name "ard" is registered in {{iana-service-name}}.

Service instance names such as "Travel" are user-visible names; {{RFC6763}} allows them to change, and a server need not preserve their case ({{RFC4343}}). A client SHOULD NOT use an instance name as a persistent identifier of a manifest.

## Origin-Based Mechanisms {#origin-mechanisms}

The mechanisms in this section use an HTTP request to the origin `https://<domain>/`.

### Well-Known URI {#well-known}

A publisher makes its manifest available at the well-known URI {{RFC8615}} with the suffix "ard.json". For the domain example.com, the well-known URI is:

~~~
https://example.com/.well-known/ard.json
~~~

A publisher supporting this mechanism MUST respond to a GET request for this URI with an ARD manifest or with a redirect to one. The manifest carries the media type defined in {{ARD}}, and a client SHOULD send it in the Accept header field. The client MUST follow at most one redirect (301, 302, 303, 307, or 308 with a Location field, {{Section 15.4 of RFC9110}}) and records the final URI as the entry point. A response with another media type, or a redirect to a further redirect, means that there is no entry point at this origin ({{depth}}). A server that hosts no manifest SHOULD respond with 404 (Not Found) and MAY include Problem Details {{RFC9457}}.

Responses to the well-known URI, including redirects and 404 responses, are cacheable under {{RFC9111}}. A client reuses a stored response while it is fresh ({{procedure}}). A freshness lifetime of several hours is appropriate for a manifest whose location rarely changes.

The scope of a well-known URI is its origin ({{Section 3 of RFC8615}}); a manifest at "https://example.com/.well-known/ard.json" provides no information about "https://agents.example.com/". A publisher with manifests on several hosts can serve a manifest at the apex that links to the others, or can enumerate them with DNS-SD ({{dns-sd}}).

The registration of the suffix is in {{iana-well-known}}.

### Link Relation {#link-relation}

A publisher MAY include a link to a manifest in any HTTP response using the "ard" link relation {{RFC8288}} in a Link header field. The link target is an ARD manifest. A publisher supporting this mechanism SHOULD respond to a HEAD request for the root resource of its origin with a Link header field carrying the relation, following {{Section 2 of RFC9727}}. The following is an example:

~~~ http-message
HEAD / HTTP/1.1
Host: example.com

~~~

~~~ http-message
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Content-Length: 1532
Link: <https://agents.example.com/manifest>; rel="ard"

~~~

The client reads the Link field of the root response regardless of its status code and does not follow a redirect of the root resource. The relation MAY also appear in an HTML link element in the root resource ({{Appendix A.1 of RFC8288}}), for publishers that cannot set header fields. A client that retrieves the root resource with GET reads link elements in an HTML response in the same way as the Link header field. Links in a response from the publisher's own origin have that origin as their source. Links in third-party documents are hints with the third party as their source. The registration of the relation is in {{iana-link-relation}}.

## Local Network Mechanisms {#local-mechanisms}

### Network-Provided Domain Name {#provided-domain}

A client without a domain name can obtain one from the network through the DHCPv4 Domain Name option ({{Section 3.17 of RFC2132}}), the DHCPv6 Domain Search List option {{RFC3646}}, or the DNS Search List option in IPv6 Router Advertisements {{RFC8106}}. The client uses such a name as the domain name in the procedure of {{procedure}}. The client records the network as the source of the name.

### Multicast DNS {#mdns}

On the local link, a client browses for "_ard._tcp.local." over Multicast DNS {{RFC6762}}, using the same PTR, SRV, and TXT records as in {{dns-sd}}. Names under "local." do not appear in certificates issued by public CAs. A publisher that advertises over Multicast DNS SHOULD set the SRV target to a unicast DNS name for which it holds a certificate, so that the entry point URI names a host the client can authenticate. The client resolves such a target through unicast DNS and ignores address records for it in a multicast answer, since a Multicast DNS responder is authoritative only for names under "local." ({{Section 6 of RFC6762}}). TLS authenticates the host in either case ({{sec-hints}}). A responder that accepts only "local." targets yields entry points the client cannot authenticate ({{sec-local}}). The client stops collecting responses after a configured interval; responses received later are processed as new hints. Where a Discovery Proxy {{RFC8766}} is deployed, the client can use {{dns-sd}} instead. Entry points learned over Multicast DNS carry the network interface as their source ({{sec-local}}).

{{I-D.jakab-dawn-agent-discovery-mdns}} describes browsing for individual agents under "_agent._tcp". The two service types are independent.

# Client Procedure {#procedure}

The procedure in this section is a RECOMMENDED default. The well-known fetch of step 4, the depth limits of {{depth}}, and the rate limiting below are requirements on every client. A client MAY reorder or omit the other steps under local policy.

The procedure takes a domain name as input, written `<domain>` below, obtained from configuration, from the user, or from the network ({{provided-domain}}). The procedure continues after a step returns an entry point. A client without a domain name performs step 1 and queries "_ard._tcp.local." over Multicast DNS ({{mdns}}); steps 2 to 5 do not apply.

1. The client uses configured entry points ({{static}}) first.
2. The client queries the SVCB record for `_index._agents.<domain>` ({{pointer-rr}}).
3. The client queries the PTR records at `_ard._tcp.<domain>` ({{dns-sd}}).
4. The client requests `https://<domain>/.well-known/ard.json` ({{well-known}}). This step MAY be performed in parallel with steps 2 and 3.
5. If steps 2 to 4 yield no entry point, the client sends a HEAD request to `https://<domain>/` and examines the Link header field for the "ard" relation ({{link-relation}}).

The procedure ends when every step has returned. A client attempts each distinct URI once per execution of the procedure and records all its sources.

The default order of preference is: configuration, then DNS answers validated with DNSSEC {{RFC4033}}, then responses from the publisher's own origin (steps 4 and 5), then unvalidated DNS answers, then Multicast DNS responses. An answer is validated when the client validated it or received it with the AD bit set from a trusted validating resolver over a secure channel ({{Section 4.9.3 of RFC4035}}); Insecure and Indeterminate answers ({{Section 4.3 of RFC4035}}) are unvalidated, and Bogus answers are discarded. An entry point is validated when every answer used to form its URI was; address records do not count, since TLS authenticates the host. Within a level, entry points are ordered by step; within a source, by SvcPriority or SRV priority. A client MAY reorder entry points under local policy. Configured entry points ({{static}}) are tried first. Entry points learned over Multicast DNS MUST rank last ({{sec-local}}).

An entry point fails if the server does not respond, if the response is not a manifest, or if the checks of {{security}} fail. A client MUST NOT retry a failed entry point from the same source before a back-off interval of at least 30 seconds. A client MUST NOT issue the DNS queries of steps 2 and 3 for the same domain name more often than the TTLs of the answers allow, including negative answers ({{RFC2308}}) and the DNSKEY and DS queries of validation. A client MUST NOT repeat the requests of steps 4 and 5 while a stored response is fresh ({{RFC9111}}).

## Indirection Depth and Outcomes {#depth}

A client follows at most one AliasMode indirection in the DNS and at most one HTTP redirect per entry point, from any mechanism; the two limits are independent. A second indirection of either kind ends the attempt. This bounds the number of round trips and prevents an attacker who controls one record or one response from leading the client through a chain of indirections.

Each attempt to resolve a hint has one of three outcomes:

{:vspace}
Entry point:
: The URI returned an ARD manifest from an authenticated origin.

No entry point:
: The URI did not respond, returned a response that is not a manifest, exceeded the depth limit, or failed the checks of {{security}}. The failure is attributed to the source.

Not permitted:
: The client's own policy did not allow the fetch, for instance a host under "local." that no certificate can authenticate ({{sec-local}}), or a host not on an allow-list. The hint is retained with its source, and no failure is attributed to the source.

# Security Considerations {#security}

Initial contact takes place before any authenticated relationship exists between the client and the publisher. In each mechanism, an attacker who controls the channel can direct the client to a manifest of the attacker's choosing. The mitigation is the same for all mechanisms: the client treats the result as a hint, retrieves the manifest from the URI, authenticates the origin, and relies on the content of each entry, as specified in {{ARD}}, to determine its publisher.

## Hints and Authority {#sec-hints}

A client MUST authenticate the TLS server for the host named in the entry point URI ({{Section 4.3.3 of RFC9110}}). For the well-known URI, that host is the publisher's own domain. For the index record, for DNS-SD, and for a link whose target is on another origin, the host is taken from the answer or the link, and a spoofed answer can direct the client to a host for which the attacker holds a valid certificate. A client SHOULD validate DNS answers with DNSSEC {{RFC4033}} where the zone is signed and SHOULD rank unvalidated answers below validated ones ({{procedure}}). This document does not establish that a manifest reached through `_index._agents.example.com` is published by "example.com"; the recorded source is an input to the per-entry publisher check that {{ARD}} defines.

Carrying a digest or a public key for the manifest in the DNS record, as {{I-D.nemethi-dawn-aid}} does for its objects, was considered and not adopted, since a manifest changes with every published entry.

## Local Network Discovery {#sec-local}

Any host on the link can respond to a Multicast DNS query. A client MUST treat entry points learned over multicast as the least trusted source. It SHOULD prefer entry points whose URI names a host it can authenticate with a certificate, and MAY apply local policy, such as a pinned key or an allow-list of hosts. A manifest found over multicast does not establish that the agents listed in it are present on the network or operated by the network's owner. A multicast query produces a response from every matching host on the link; clients MUST follow the query rate limits of {{RFC6762}}.

## Downgrade {#sec-downgrade}

A client MUST NOT fall back to "http" when an "https" entry point fails, and MUST NOT accept an entry point whose scheme is "http". The "alpn" key in SVCB records selects the HTTP version; it does not affect the requirement for TLS.

## Well-Known URI Squatting {#sec-well-known}

On shared hosting, the well-known URI can be served by a tenant rather than the domain owner ({{Section 4 of RFC8615}}). The per-entry publisher check of {{ARD}} applies to a manifest found through the well-known URI as to any other; a tenant can serve a manifest, but its entries will not pass the check as entries of the domain owner.

# Privacy Considerations {#privacy}

A DNS query for `_index._agents.example.com` or `_ard._tcp.example.com` reveals to the resolver, and to any observer on the path, that the client is querying for agent manifests of example.com. Encrypted DNS transports, discovered as described in {{RFC9462}}, limit the observers to the resolver. The well-known fetch is indistinguishable from an ordinary connection to the domain. The TLS Server Name Indication reveals the TargetName host unless the "ech" key is used, and DNSSEC validation adds DNSKEY and DS queries to the parent zones.

Browsing over Multicast DNS reveals to all hosts on the link that the client is looking for agent manifests, and a responding host reveals that it advertises one. Deployments where this is a concern can use unicast DNS-SD through a Discovery Proxy {{RFC8766}} with access control on the zone, or configuration. The service instance names under `_ard._tcp.<domain>` can be enumerated by any party; they identify manifests that a publisher has chosen to make discoverable, and they do not identify people or individual agents.

Retrieving the manifest reveals the client's address to the publisher.

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
: The resource is an ARD manifest.

## Link Relation {#iana-link-relation}

IANA is asked to register the following entry in the "Link Relations" registry defined in {{RFC8288}}:

{:vspace}
Relation name:
: ard

Description:
: Refers to an Agent Resource Discovery (ARD) manifest of the publisher of the link context.

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
: Agent Resource Discovery (ARD) manifest

Reference:
: This document, {{dns-sd}}.

--- back

# Related Work {#related}

{{I-D.jimenez-dawn-discovery-landscape}} surveys agent discovery mechanisms and separates lookup, name, description, trust, and interaction. Initial contact is the lookup component for the case where the result is a manifest. The entry point of {{entry-point}} is a subset of the minimum discoverable information of {{I-D.cui-dawn-mdi-model}}, the well-known URI is the predictable entry point that REQ-PROTO-4 of {{I-D.king-dawn-requirements}} asks for, and the terminology of {{I-D.farrel-dawn-terminology}} applies.

DNS-AID {{I-D.mozleywilliams-dnsop-dnsaid}} publishes agents as SVCB records and an organization index under `_index._agents.<domain>`, and leaves the data behind the index out of scope. {{pointer-rr}} uses the index record with an ARD manifest as its target. {{I-D.mk-dnsop-svcb-well-known}} defines a SvcParamKey through which an SVCB or HTTPS record announces the well-known URI suffixes a host serves; once the key is registered, the HTTPS record of a domain can announce the suffix of {{well-known}} before the client connects. The DNS-AID reference implementation follows an off-domain pointer only when the record is DNSSEC-validated or the manifest is signed against the domain's key set, and refuses redirects; {{depth}} allows one redirect, and the trust decision for off-domain pointers is left to the publisher check of {{ARD}}. The ARD specification {{ARD-SPEC}}, from which {{ARD}} derives, requires the well-known fetch of "/.well-known/ard.json" and lists `_entries._agents` for a static entry source and `_search._agents` for a registry endpoint.

{{I-D.nemethi-dawn-aid}}, {{I-D.morrison-mcp-dns-discovery}}, and {{I-D.seethiraju-dawn-dan}} locate individual agents or MCP servers through DNS records at `_agent.<domain>`, at `_mcp.<domain>`, or in new resource record types; none defines a manifest entry point. {{I-D.jakab-dawn-agent-discovery-mdns}} browses for agents on the local link under "_agent._tcp". {{I-D.zahed-acap}}, {{I-D.pro-adp-agent-discovery}}, and {{I-D.besleaga-agentic-knowledge-wellknown}} publish operator-level discovery documents at well-known URIs. The last publishes an {{RFC9264}} link set, which is the closest existing design to publishing an ARD manifest as an {{RFC9727}} API catalog ({{open-issues}}).

{{Section 4.1 of RFC9176}} lists how a CoRE endpoint finds a Resource Directory: configuration, a Router Advertisement option, DNS-SD, and multicast. {{static}}, {{provided-domain}}, {{dns-sd}}, and {{mdns}} are the ARD counterparts. {{RFC9461}} and {{RFC9462}} are the SVCB mapping and the discovery procedure for encrypted DNS resolvers; {{pointer-rr}} and {{procedure}} follow the same structure.

# Open Issues {#open-issues}

The following questions are to be settled before the document is stable. This section is to be removed before publication.

1. API catalog profile. Issue #2 on the ARD repository proposes publishing the manifest as an {{RFC9727}} API catalog under "/.well-known/api-catalog" with an ARD profile. If adopted, this document registers no suffix.
2. Pointer label. This document uses the DNS-AID organization index `_index._agents`, whose data format DNS-AID leaves out of scope. The DNS-AID reference implementation publishes `_catalog._agents` and {{ARD-SPEC}} lists `_entries._agents` for the same pointer; both are to be aligned with this document. DNS-AID, as the owner of "_agents" in the {{RFC8552}} registry, is asked to list an ARD manifest as one kind of index target.
3. Suffix. "ard.json" matches {{ARD-SPEC}} and deployed code. A suffix without the extension, "ard", was considered.
4. Reference status. {{ARD}} is a normative reference to a companion individual draft submitted together with this document. {{I-D.mozleywilliams-dnsop-dnsaid}} is an individual draft cited normatively, for the index record name and the TargetName rule of {{pointer-rr}}.
5. HTTPS record at the apex. An earlier version let the HTTPS record of a domain announce the suffix through the "well-known" SvcParamKey of {{I-D.mk-dnsop-svcb-well-known}}. The mechanism was removed because the key has no registered number, syntax, or encoding yet; it is to be reconsidered once the key is registered.
6. Registry endpoints. {{ARD-SPEC}} also points to a registry endpoint through `_search._agents.<domain>`. This document yields manifests only. Extending the entry point to registry endpoints is a question for DAWN.

# Acknowledgments
{:numbered="false"}

The split of the ARD work into initial contact, lookup, and registration documents was proposed by Jari Arkko. R.V. Guha co-wrote the ARD specification this document builds on. Wes Hardaker and Sam Sharaf took part in the discussions that shaped the scope. The work of Jim Mozley and Daniel King on the organization index provided the DNS binding used here. The depth limit and the fixed outcomes follow a discussion on the DAWN list started by Enrique Somoza and continued by Francesco Marinoni Moretto and Balazs Nemethi.
