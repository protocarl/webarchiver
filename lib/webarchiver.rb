#!/usr/bin/env macruby

framework 'WebKit'

class WebArchiver

  def self.archive url, file, seconds
    self.archiveURL url, toFile:file, timeout:seconds
  end

  def self.archiveURL url, toFile:file, timeout:seconds
    archiver = WebArchiver.alloc.initWithURL(url, toFile:file)
    archiver.archiveWithTimeout(seconds.to_i)
  end

  def initWithURL url, toFile:file
    @url, @file = url, file

    @webView = WebView.alloc.init
    @webView.frameLoadDelegate = self

    @done = false

    self
  end

  def archiveWithTimeout seconds
    request = NSURLRequest.requestWithURL(NSURL.URLWithString(@url))
    @webView.mainFrame.loadRequest(request)

    runLoop = NSRunLoop.currentRunLoop
    toDate  = NSDate.dateWithTimeIntervalSinceNow(seconds)

    while !done?
      runLoop.runMode(NSDefaultRunLoopMode, beforeDate:toDate)
      break if NSDate.date.earlierDate(toDate) == toDate
    end
  end

  def done?
    @done
  end

  # frameLoadDelegate methods

  def webView sender, didFinishLoadForFrame:frame
    data = frame.dataSource.webArchive.data
    file = cleanseFilename(@file || frame.dataSource.pageTitle)

    data.writeToFile(file, atomically:false)

    @done = true
 end

  def webView sender, didFailProvisionalLoadWithError:error, forFrame:frame
    @done = true
  end

  def webView sender, didFailLoadWithError:error, forFrame:frame
    @done = true
  end

private

  def cleanseFilename(file)
    file += '.webarchive' unless file =~ /\.webarchive$/
    file.gsub('/', '-')
  end

end
