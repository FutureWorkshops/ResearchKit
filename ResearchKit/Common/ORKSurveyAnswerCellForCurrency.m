//
/*
 Copyright (c) 2020, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ORKSurveyAnswerCellForCurrency.h"

#import "ORKTextFieldView.h"
#import "ORKDontKnowButton.h"

#import "ORKAnswerFormat_Internal.h"
#import "ORKQuestionStep_Internal.h"

#import "ORKHelpers_Internal.h"

#import <ResearchKit/ResearchKit-Swift.h>

@implementation ORKSurveyAnswerCellForCurrency {
    CurrencyFormatter *_currencyFormatter;
    CurrencyUITextFieldDelegate *_currencyUITextFieldDelegate;
}

- (ORKUnitTextField *)textField {
    return self.textFieldView.textField;
}

- (nullable NSString *)stringFromNumber:(NSNumber *)number {
    return [_currencyFormatter stringFrom:number.doubleValue];
}

- (nullable NSNumber *)numberFromString:(NSString *)string {
    return [_currencyFormatter doubleAsNSNumberFrom:string];
}

- (nullable NSString *)sanitizedText:(NSString *)text {
    return text;
}

- (void)numberCell_initialize {
    [super numberCell_initialize];
    
    ORKCurrencyAnswerFormat *currencyAnswerFormat = (ORKCurrencyAnswerFormat *)self.step.answerFormat;
    
    _currencyFormatter = currencyAnswerFormat.currencyFormatter;
    _currencyUITextFieldDelegate = [[CurrencyUITextFieldDelegate alloc] initWithFormatter:currencyAnswerFormat.currencyFormatter];
    
    self.textField.delegate = _currencyUITextFieldDelegate;
}

- (void)setAnswerWithText:(NSString *)text {
    BOOL updateInput = NO;
    id answer = ORKNullAnswerValue();
    if (text.length) {
        answer = [_currencyFormatter unformattedWithString:text];
        if (!answer) {
            answer = ORKNullAnswerValue();
            updateInput = YES;
        }
    }
    
    [self ork_setAnswer:answer];
    if (updateInput) {
        [self answerDidChange];
    }
}

@end
