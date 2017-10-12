//
//  XMPPCapabilities+XEP_0359.m
//  XMPPFramework
//
//  Created by Chris Ballinger on 10/11/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "XMPPCapabilities+XEP_0359.h"
#import "XMPPMessage+XEP0045.h"
#import "XMPPMessage+XEP_0359.h"
#import "NSXMLElement+XEP_0359.h"

@implementation XMPPCapabilities (XEP_0359)

- (BOOL) hasValidStanzaId:(XMPPMessage*)message {
    if (!message) { return NO; }
    XMPPJID *stanzaIdBy = message.stanzaIdBy;
    NSString *stanzaId = message.stanzaId;
    if (!stanzaId || !stanzaIdBy) {
        return NO;
    }
    XMPPJID *expectedBy = nil;
    if (message.isGroupChatMessage) {
        expectedBy = message.from.bareJID;
    } else {
        expectedBy = self.xmppStream.myJID.bareJID;
    }
    if (expectedBy) { return NO; }
    
    // The value of the 'by' attribute MUST be the XMPP address of the entity assigning the unique and stable stanza ID. For one-on-one messages the assigning entity is the account. In groupchats the assigning entity is the room. Note that XMPP addresses are normalized as defined in RFC 6122 [4].

    BOOL expectedByMatches = [stanzaIdBy isEqualToJID:expectedBy options:XMPPJIDCompareBare];
    if (!expectedByMatches) {
        return NO;
    }
    
    // Before processing the stanza ID of a message and using it for deduplication purposes or for MAM catchup, the receiving entity SHOULD ensure that the stanza ID could not have been faked, by verifying that the entity referenced in the by attribute does annouce the 'urn:xmpp:sid:0' namespace in its disco features.
    NSXMLElement *caps = [self.xmppCapabilitiesStorage capabilitiesForJID:expectedBy xmppStream:self.xmppStream];
    if (!caps) { return NO; }
    BOOL supportsStanzaIdFromCaps = [self supportsStanzaIdFromCaps:caps];
    if (!supportsStanzaIdFromCaps) {
        return NO;
    }
    
    // We've passed all the checks
    return YES;
}

- (BOOL) supportsStanzaIdFromCaps:(NSXMLElement*)caps {
    __block BOOL supportsStanzaId = NO;
    NSArray <NSXMLElement*> *featureElements = [caps elementsForName:@"feature"];
    [featureElements enumerateObjectsUsingBlock:^(NSXMLElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *featureName = [obj attributeStringValueForName:@"var"];
        if ([featureName isEqualToString:XMPPStanzaIdXmlns]){
            supportsStanzaId = YES;
            *stop = YES;
        }
    }];
    return supportsStanzaId;
}

@end