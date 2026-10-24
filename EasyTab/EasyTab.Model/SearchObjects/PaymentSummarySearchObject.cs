using System;

namespace EasyTab.Model.SearchObjects;

public class PaymentSummarySearchObject
{
    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
    public int? LocaleId { get; set; }
}
