/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0; you may not use this file except in compliance with the Elastic License
 * 2.0.
 */

package org.elasticsearch.xpack.esql.action;

import org.elasticsearch.plugins.Plugin;
import org.elasticsearch.test.ESIntegTestCase;
import org.elasticsearch.xpack.esql.plugin.EsqlPlugin;

import java.util.Collection;
import java.util.Collections;
import java.util.List;

import static org.elasticsearch.test.ESIntegTestCase.Scope.SUITE;

@ESIntegTestCase.ClusterScope(scope = SUITE, numDataNodes = 0, numClientNodes = 0, maxNumDataNodes = 0)
public class EsqlActionIT extends ESIntegTestCase {

    public void testEsqlAction() {
        int value = randomIntBetween(0, Integer.MAX_VALUE);
        EsqlQueryResponse response = new EsqlQueryRequestBuilder(client(), EsqlQueryAction.INSTANCE).query("row " + value).get();
        assertEquals(List.of(List.of(value)), response.values());
    }

    @Override
    protected Collection<Class<? extends Plugin>> nodePlugins() {
        return Collections.singletonList(EsqlPlugin.class);
    }
}