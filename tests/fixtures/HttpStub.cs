public class FixtureHandler : HttpMessageHandler {
  public static int Active,Peak,Requests;
  public static int ActiveChecks,PeakChecks;
  public static string LockPath;
  public static FileStream Hold;
  public static readonly byte[] Data=System.Text.Encoding.UTF8.GetBytes(new string('x',131073));
  static readonly ConcurrentDictionary<string,int> Attempts=new ConcurrentDictionary<string,int>();
  protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request,CancellationToken token) {
    Interlocked.Increment(ref Requests);
    int active=Interlocked.Increment(ref Active), observed;
    do { observed=Peak; if(observed>=active) break; } while(Interlocked.CompareExchange(ref Peak,active,observed)!=observed);
    string path=request.RequestUri.AbsolutePath;
    int count=Attempts.AddOrUpdate(path,1,(key,old)=>old+1);
    try {
      await Task.Delay(path=="/timeout"?1000:30,token);
      if(path=="/retry"&&count<3) return new HttpResponseMessage(HttpStatusCode.ServiceUnavailable);
      var result=new HttpResponseMessage(HttpStatusCode.OK) { Content=new ByteArrayContent(Data) };
      if(path=="/partial"&&count<3) result.Content=new StreamContent(new BrokenStream(Data));
      if(path=="/locked"&&Hold==null) Hold=new FileStream(LockPath,FileMode.Open,FileAccess.Read,FileShare.Read);
      if(path=="/redirect") { result.StatusCode=HttpStatusCode.Redirect; result.Headers.Location=new Uri("https://release-assets.githubusercontent.com/ok"); }
      if(path=="/evil") { result.StatusCode=HttpStatusCode.Redirect; result.Headers.Location=new Uri("https://evil.example/payload"); }
      if(path=="/loop") { result.StatusCode=HttpStatusCode.Redirect; result.Headers.Location=new Uri("https://libraries.minecraft.net/loop"); }
      return result;
    } finally { Interlocked.Decrement(ref Active); }
  }
  public static int Count(string path) { int n; return Attempts.TryGetValue(path,out n)?n:0; }
  public static IDisposable Check() {
    int active=Interlocked.Increment(ref ActiveChecks), observed;
    do { observed=PeakChecks; if(observed>=active) break; } while(Interlocked.CompareExchange(ref PeakChecks,active,observed)!=observed);
    Thread.Sleep(15); return new CheckGuard();
  }
  sealed class CheckGuard : IDisposable { public void Dispose() { Interlocked.Decrement(ref ActiveChecks); } }
}
public class BrokenStream : Stream {
  readonly MemoryStream Inner;
  readonly bool Broken;
  public BrokenStream(byte[] bytes,bool broken=true) { Inner=new MemoryStream(bytes); Broken=broken; }
  public override int Read(byte[] buffer,int offset,int count) {
    if(Broken&&Inner.Position>=Inner.Length/2) throw new IOException("Injected interrupted response");
    return Inner.Read(buffer,offset,(int)Math.Min(Math.Min(count,65536),Broken?Inner.Length/2-Inner.Position:count));
  }
  public override Task<int> ReadAsync(byte[] buffer,int offset,int count,CancellationToken token) { token.ThrowIfCancellationRequested(); return Task.FromResult(Read(buffer,offset,count)); }
  public override bool CanRead { get { return true; } }
  public override bool CanWrite { get { return false; } }
  public override bool CanSeek { get { return false; } }
  public override long Length { get { return Inner.Length; } }
  public override long Position { get { return Inner.Position; } set { throw new NotSupportedException(); } }
  public override void Flush() {}
  public override long Seek(long offset,SeekOrigin origin) { throw new NotSupportedException(); }
  public override void SetLength(long value) { throw new NotSupportedException(); }
  public override void Write(byte[] buffer,int offset,int count) { throw new NotSupportedException(); }
  protected override void Dispose(bool disposing) { if(disposing) Inner.Dispose(); base.Dispose(disposing); }
}
public class RejectContext : SynchronizationContext {
  public override void Post(SendOrPostCallback callback,object state) { throw new Exception("Unexpected synchronization context capture"); }
}
