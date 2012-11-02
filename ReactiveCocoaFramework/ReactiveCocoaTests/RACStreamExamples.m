//
//  RACStreamExamples.m
//  ReactiveCocoa
//
//  Created by Justin Spahr-Summers on 2012-11-01.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACSpecs.h"
#import "RACStreamExamples.h"

#import "RACStream.h"
#import "RACUnit.h"

NSString * const RACStreamExamples = @"RACStreamExamples";
NSString * const RACStreamExamplesClass = @"RACStreamExamplesClass";
NSString * const RACStreamExamplesVerifyValuesBlock = @"RACStreamExamplesVerifyValuesBlock";

SharedExampleGroupsBegin(RACStreamExamples)

sharedExamplesFor(RACStreamExamples, ^(NSDictionary *data) {
	Class streamClass = data[RACStreamExamplesClass];
	void (^verifyValues)(id<RACStream>, NSArray *) = data[RACStreamExamplesVerifyValuesBlock];

	__block id<RACStream> (^streamWithValues)(NSArray *);
	
	before(^{
		streamWithValues = [^(NSArray *values) {
			id<RACStream> stream = nil;

			for (id value in values) {
				id<RACStream> valueSeq = [streamClass return:value];
				if (stream == nil) {
					stream = valueSeq;
				} else {
					stream = [stream concat:valueSeq];
				}
			}

			return stream;
		} copy];
	});

	it(@"should return an empty stream", ^{
		id<RACStream> stream = [streamClass empty];
		verifyValues(stream, @[]);
	});

	it(@"should lift a value into a stream", ^{
		id<RACStream> stream = [streamClass return:RACUnit.defaultUnit];
		verifyValues(stream, @[ RACUnit.defaultUnit ]);
	});

	describe(@"-concat:", ^{
		it(@"should concatenate two streams", ^{
			id<RACStream> stream = [[streamClass return:@0] concat:[streamClass return:@1]];
			verifyValues(stream, @[ @0, @1 ]);
		});

		it(@"should concatenate three streams", ^{
			id<RACStream> stream = [[[streamClass return:@0] concat:[streamClass return:@1]] concat:[streamClass return:@2]];
			verifyValues(stream, @[ @0, @1, @2 ]);
		});
	});

	it(@"should flatten", ^{
		id<RACStream> stream = [[streamClass return:[streamClass return:RACUnit.defaultUnit]] flatten];
		verifyValues(stream, @[ RACUnit.defaultUnit ]);
	});

	describe(@"-bind:", ^{
		it(@"should return the result of binding a single value", ^{
			id<RACStream> stream = [[streamClass return:@0] bind:^(NSNumber *value) {
				NSNumber *newValue = @(value.integerValue + 1);
				return [streamClass return:newValue];
			}];

			verifyValues(stream, @[ @1 ]);
		});

		it(@"should concatenate the result of binding multiple values", ^{
			id<RACStream> baseStream = streamWithValues(@[ @0, @1 ]);
			id<RACStream> stream = [baseStream bind:^(NSNumber *value) {
				NSNumber *newValue = @(value.integerValue + 1);
				return [streamClass return:newValue];
			}];

			verifyValues(stream, @[ @1, @2 ]);
		});
	});

	it(@"should map", ^{
		id<RACStream> baseStream = streamWithValues(@[ @0, @1, @2 ]);
		id<RACStream> stream = [baseStream map:^(NSNumber *value) {
			return @(value.integerValue + 1);
		}];

		verifyValues(stream, @[ @1, @2, @3 ]);
	});

	it(@"should filter", ^{
		id<RACStream> baseStream = streamWithValues(@[ @0, @1, @2, @3, @4, @5, @6 ]);
		id<RACStream> stream = [baseStream filter:^ BOOL (NSNumber *value) {
			return value.integerValue % 2 == 0;
		}];

		verifyValues(stream, @[ @0, @2, @4, @6 ]);
	});

	it(@"should start with a value", ^{
		id<RACStream> stream = [[streamClass return:@1] startWith:@0];
		verifyValues(stream, @[ @0, @1 ]);
	});

	describe(@"-skip:", ^{
		__block NSArray *values;
		__block id<RACStream> stream;

		before(^{
			values = @[ @0, @1, @2 ];
			stream = streamWithValues(values);
		});

		it(@"should skip any valid number of values", ^{
			for (NSUInteger i = 0; i < values.count; i++) {
				verifyValues([stream skip:i], [values subarrayWithRange:NSMakeRange(i, values.count - i)]);
			}
		});

		it(@"should return an empty stream when skipping too many values", ^{
			verifyValues([stream skip:4], @[]);
		});
	});

	describe(@"-take:", ^{
		__block NSArray *values;
		__block id<RACStream> stream;

		before(^{
			values = @[ @0, @1, @2 ];
			stream = streamWithValues(values);
		});

		it(@"should take any valid number of values", ^{
			for (NSUInteger i = 0; i < values.count; i++) {
				verifyValues([stream take:i], [values subarrayWithRange:NSMakeRange(0, i)]);
			}
		});

		it(@"should return the same stream when taking too many values", ^{
			expect([stream take:4]).to.equal(stream);
		});
	});
});

SharedExampleGroupsEnd
