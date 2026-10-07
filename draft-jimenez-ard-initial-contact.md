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
