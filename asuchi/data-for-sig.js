const adminVerificationData = (
  caller,
  eventId,
  nonce
) => {
  return {
    domainseparator: {
      name: "szeeta",
      version: "0.0.1",
      chainId: 80001,
      verifyingContract: "0xdd62E5C5543eEf54b249C689b4458C559AE2eD10",
    },

    types: {
      AdminCall: [
        { name: "caller", type: "address" },
        { name: "eventId", type: "uint256" },
        { name: "nonce", type: "uint256" },
      ],
    },

    value: {
      caller,
      eventId,
      nonce,
    },
  };
};

exports.sigOut = adminVerificationData;
