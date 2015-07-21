﻿namespace Microsoft.VisualStudio.Sdk.TestFramework
{
    using Xunit;

    /// <summary>
    /// Defines the "MockedVS" xunit test collection.
    /// </summary>
    [CollectionDefinition(Collection)]
    public class MockedVS : ICollectionFixture<GlobalServiceProvider>, ICollectionFixture<MefHosting>
    {
        /// <summary>
        /// The name of the xunit test collection.
        /// </summary>
        public const string Collection = "MockedVS";
    }
}
