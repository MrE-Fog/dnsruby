require 'test/unit'
require 'dnsruby'
include Dnsruby

class TestDlv < Test::Unit::TestCase
  def test_dlv
    # Enable DLV (only) for validation.
    # Try to validate some records which can only be done through dlv
    # OK - if we don't configure trust anchors, and there is no signed root, then this is easy!
        Dnsruby::Dnssec.clear_trusted_keys
    Dnsruby::Dnssec.clear_trust_anchors
    Dnsruby::InternalResolver.clear_caches
    # @TODO@ Should use whole RRSet of authoritative NS for these resolvers,
    # not individual servers!
    res = Dnsruby::Resolver.new("a.ns.se")
    res.add_server("b.ns.se")
    res.dnssec=true
    ret = res.query("se.", Dnsruby::Types.ANY)
    assert(ret.security_level == Dnsruby::Message::SecurityLevel::INSECURE)

    res = Dnsruby::Resolver.new("ns3.nic.se")
    res.add_server("ns2.nic.se")
    res.dnssec = true
    ret = res.query("ns2.nic.se", Dnsruby::Types.A)
    assert(ret.security_level == Dnsruby::Message::SecurityLevel::INSECURE)

    # Load DLV key
    dlv_key = RR.create("dlv.isc.org. IN DNSKEY 257 3 5 BEAAAAPHMu/5onzrEE7z1egmhg/WPO0+juoZrW3euWEn4MxDCE1+lLy2 brhQv5rN32RKtMzX6Mj70jdzeND4XknW58dnJNPCxn8+jAGl2FZLK8t+ 1uq4W+nnA3qO2+DL+k6BD4mewMLbIYFwe0PG73Te9fZ2kJb56dhgMde5 ymX4BI/oQ+cAK50/xvJv00Frf8kw6ucMTwFlgPe+jnGxPPEmHAte/URk Y62ZfkLoBAADLHQ9IrS2tryAe7mbBZVcOwIeU/Rw/mRx/vwwMCTgNboM QKtUdvNXDrYJDSHZws3xiRXF1Rf+al9UmZfSav/4NWLKjHzpT59k/VSt TDN0YUuWrBNh")
    Dnssec.add_dlv_key(dlv_key)
    Dnsruby::InternalResolver.clear_caches


    res = Dnsruby::Resolver.new("ns3.nic.se")
    res.add_server("ns2.nic.se")
    res.dnssec = true
    ret = res.query("ns2.nic.se", Dnsruby::Types.A)
    assert(ret.security_level == Dnsruby::Message::SecurityLevel::SECURE)

    res = Dnsruby::Resolver.new("a.ns.se")
    res.add_server("b.ns.se")
    res.dnssec=true
    ret = res.query("se.", Dnsruby::Types.ANY)
    assert(ret.security_level == Dnsruby::Message::SecurityLevel::SECURE)

    res = Dnsruby::Resolver.new("a.ns.nic.cz")
    res.add_server("b.ns.nic.cz")
    ret = res.query("b.ns.nic.cz", Dnsruby::Types.A)
    assert(ret.security_level == Dnsruby::Message::SecurityLevel::SECURE)
  end

  def test_scrub_non_authoritative
    res = Dnsruby::Resolver.new("ns1.frobbit.se")
    res.add_server("ns.cafax.se")
    ret = res.query("frobbit.se")
    assert(ret.security_level == Dnsruby::Message::SecurityLevel::SECURE)
  end
end