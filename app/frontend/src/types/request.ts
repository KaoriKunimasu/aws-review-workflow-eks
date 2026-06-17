export type WorkflowRequest = {
  requestId: string;
  title: string;
  description: string;
  sourceLanguage: string;
  targetLanguage: string;
  status?: string;
  createdAt: string;
  createdBy?: string;
};

export type ListRequestsResponse = {
  items: WorkflowRequest[];
  count: number;
  hasMore: boolean;
};

export type CreateRequestPayload = {
  title: string;
  requestType: string;
  sourceLanguage: string;
  targetLanguage: string;
  sourceText: string;
  targetText?: string;
  category?: string;
};


export type CreateRequestResponse = {
  item: WorkflowRequest;
  message?: string;
};
