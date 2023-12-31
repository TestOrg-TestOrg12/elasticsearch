/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. Licensed under the Elastic License
 * 2.0; you may not use this file except in compliance with the Elastic License
 * 2.0.
 */

package org.elasticsearch.xpack.ml.utils;

import org.elasticsearch.ElasticsearchStatusException;
import org.elasticsearch.action.ActionListener;
import org.elasticsearch.client.internal.Client;
import org.elasticsearch.core.TimeValue;
import org.elasticsearch.rest.RestStatus;
import org.elasticsearch.tasks.TaskInfo;
import org.elasticsearch.xpack.core.ml.MlTasks;

import static org.elasticsearch.xpack.core.ml.MlTasks.downloadModelTaskDescription;

/**
 * Utility class for retrieving download tasks created by a PUT trained model API request.
 */
public class TaskRetriever {
    /**
     * Returns a {@link TaskInfo} if one exists representing an in-progress trained model download.
     *
     * @param client a {@link Client} used to retrieve the task
     * @param modelId the id of the model to check for an existing task
     * @param waitForCompletion a boolean flag determine if the request should wait for an existing task to complete before returning (aka
     *                          wait for the download to complete)
     * @param listener a listener, if a task is found it is returned via {@code ActionListener.onResponse(taskInfo)}.
     *                 If a task is not found null is returned
     * @param timeout the timeout value in seconds that the request should fail if it does not complete
     */
    public static void getDownloadTaskInfo(
        Client client,
        String modelId,
        boolean waitForCompletion,
        ActionListener<TaskInfo> listener,
        TimeValue timeout
    ) {
        client.admin()
            .cluster()
            .prepareListTasks()
            .setActions(MlTasks.MODEL_IMPORT_TASK_ACTION)
            .setDetailed(true)
            .setWaitForCompletion(waitForCompletion)
            .setDescriptions(downloadModelTaskDescription(modelId))
            .setTimeout(timeout)
            .execute(ActionListener.wrap((response) -> {
                var tasks = response.getTasks();

                if (tasks.size() > 0) {
                    // there really shouldn't be more than a single task but if there is we'll just use the first one
                    listener.onResponse(tasks.get(0));
                } else {
                    listener.onResponse(null);
                }
            },
                e -> listener.onFailure(
                    new ElasticsearchStatusException(
                        "Unable to retrieve task information for model id [{}]",
                        RestStatus.INTERNAL_SERVER_ERROR,
                        e,
                        modelId
                    )
                )
            ));
    }

    private TaskRetriever() {}
}
