#include <node.h>
#include <node_object_wrap.h>
#include <nan.h>

namespace CustomRunInThisContext {
  using v8::FunctionCallbackInfo;
  using v8::Local;
  using v8::Object;
  using v8::Script;
  using v8::ScriptCompiler;
  using v8::ScriptOrigin;
  using v8::String;
  using v8::TryCatch;
  using v8::UnboundScript;
  using v8::Value;

  static void RunInThisContextCached(const FunctionCallbackInfo<Value>& args) {
    Local<String> code = args[0]->ToString(args.GetIsolate());
    Local<String> filename = args[1]->ToString(args.GetIsolate());
    Local<Object> bufferObj = args[2]->ToObject();
    uint8_t* bufferData = reinterpret_cast<uint8_t*>(node::Buffer::Data(bufferObj));
    size_t bufferLength = node::Buffer::Length(bufferObj);

    auto cachedData = new ScriptCompiler::CachedData(bufferData, bufferLength);
    ScriptOrigin origin(filename);
    ScriptCompiler::Source source(code, origin, cachedData);
    Local<UnboundScript> unbound_script =
        ScriptCompiler::CompileUnbound(args.GetIsolate(), &source, ScriptCompiler::CompileOptions::kConsumeCodeCache);

    Local<Script> script = unbound_script->BindToCurrentContext();
    Local<Value> result = script->Run();
    Local<Object> returnValue = Nan::New<v8::Object>();
    Nan::Set(returnValue, Nan::New("result").ToLocalChecked(), result);
    Nan::Set(returnValue, Nan::New("wasRejected").ToLocalChecked(), Nan::New(source.GetCachedData()->rejected));
    args.GetReturnValue().Set(returnValue);
  }

  static void RunInThisContext(const FunctionCallbackInfo<Value>& args) {
    Local<String> code = args[0]->ToString(args.GetIsolate());
    Local<String> filename = args[1]->ToString(args.GetIsolate());
    ScriptOrigin origin(filename);
    ScriptCompiler::Source source(code, origin);
    Local<UnboundScript> unbound_script =
        ScriptCompiler::CompileUnbound(args.GetIsolate(), &source, ScriptCompiler::CompileOptions::kProduceCodeCache);

    Local<Script> script = unbound_script->BindToCurrentContext();

    Local<Value> result = script->Run();
    Local<Value> cacheBuffer = Nan::Null();
    if (source.GetCachedData() && source.GetCachedData()->data) {
      cacheBuffer = Nan::CopyBuffer(reinterpret_cast<const char*>(source.GetCachedData()->data), source.GetCachedData()->length).ToLocalChecked();
    }

    Local<Object> returnValue = Nan::New<v8::Object>();
    Nan::Set(returnValue, Nan::New("cacheBuffer").ToLocalChecked(), cacheBuffer);
    Nan::Set(returnValue, Nan::New("result").ToLocalChecked(), result);
    args.GetReturnValue().Set(returnValue);
  }

  void Init(Local<Object> exports) {
    NODE_SET_METHOD(exports, "runInThisContext", RunInThisContext);
    NODE_SET_METHOD(exports, "runInThisContextCached", RunInThisContextCached);
  }

  NODE_MODULE(cached_run_in_this_context, Init)
}
